package com.jatin.eyecaretimer

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.PowerManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat

/**
 * Native owner for the active timer cadence while Flutter is suspended.
 *
 * Flutter remains authoritative and reconciles the original absolute deadline
 * on resume. This service mirrors the cadence, persists enough state to recover
 * from process death, and advances alarms across automatic work/break cycles.
 */
class TimerForegroundService : Service() {
    private val handler = Handler(Looper.getMainLooper())

    var deadlineMillis: Long = 0L
    var isBreak = false
    var breakMode = "gentle"
    var workDurationSeconds = 0
    var breakDurationSeconds = 0
    var longBreakEnabled = false
    var longBreakDurationSeconds = 0
    var longBreakEveryCycles = 0
    var autoRunEnabled = false
    var autoRunCycleLimit = 0
    var streakCount = 0
    var completedAutoRunCycles = 0
    var allowSkip = true
    var allowPostpone = true
    var postponeDurationSeconds = 120
    var maxConsecutiveSkips = 0
    var consecutiveSkips = 0
    var smartIdleEnabled = true
    var naturalBreakCreditEnabled = true
    var postponedBreakDuration = -1
    var currentPhaseInitialDuration = 0
    var autoPostponeApps = ""
    var osFocusDndEnabled = false

    private var currentDateString: String? = null

    private fun getTodayDateString(): String {
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
        return sdf.format(java.util.Date())
    }
    var screenOffTimeMillis = 0L
    var isScreenOffPaused = false
    var pausedRemainingSeconds = 0L
    val pendingEvents = mutableListOf<Map<String, Any>>()

    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (context == null || intent == null) return
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    if (naturalBreakCreditEnabled) {
                        screenOffTimeMillis = System.currentTimeMillis()
                    }
                    if (smartIdleEnabled && !isBreak && deadlineMillis > 0L && !isScreenOffPaused) {
                        isScreenOffPaused = true
                        pausedRemainingSeconds = secondsRemaining()
                        handler.removeCallbacks(tick)
                        cancelExactAlarm()
                        saveState()
                    }
                }
                Intent.ACTION_SCREEN_ON -> {
                    val km = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    val isLocked = km?.isKeyguardLocked ?: false
                    if (!isLocked) {
                        handleUserResumed(context)
                    }
                }
                Intent.ACTION_USER_PRESENT -> {
                    handleUserResumed(context)
                }
            }
        }
    }

    private fun handleUserResumed(context: Context) {
        val offTime = screenOffTimeMillis
        if (naturalBreakCreditEnabled && offTime > 0L) {
            screenOffTimeMillis = 0L
            val elapsedOffSeconds = (System.currentTimeMillis() - offTime) / 1000L
            if (elapsedOffSeconds >= breakDurationSeconds) {
                isBreak = false
                isScreenOffPaused = false
                pausedRemainingSeconds = 0L
                deadlineMillis = System.currentTimeMillis() + workDurationSeconds * 1000L
                pendingEvents.add(mapOf(
                    "type" to "naturalBreakCredited",
                    "timestamp" to System.currentTimeMillis(),
                    "durationSeconds" to workDurationSeconds
                ))
                saveState()
                presentCurrentPhase()
                resumeCurrentPhase()
                return
            }
        }

        if (smartIdleEnabled && isScreenOffPaused) {
            isScreenOffPaused = false
            deadlineMillis = System.currentTimeMillis() + pausedRemainingSeconds * 1000L
            saveState()
            presentCurrentPhase()
            resumeCurrentPhase()
        }
    }

    override fun onCreate() {
        super.onCreate()
        activeService = this
        currentDateString = getTodayDateString()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenStateReceiver, filter)
    }

    private val tick = object : Runnable {
        override fun run() {
            if (deadlineMillis <= 0L) return
            val today = getTodayDateString()
            if (currentDateString != null && currentDateString != today) {
                currentDateString = today
                streakCount = 0
                saveState()
            }
            if (secondsRemaining() <= 0L) {
                handleComplete(deadlineMillis)
                return
            }
            val manager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, buildOngoingNotification())
            TimerWidgetProvider.triggerUpdate(this@TimerForegroundService)
            handler.postDelayed(this, 1000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_COMPLETE -> {
                if (deadlineMillis <= 0L && !restoreState()) {
                    ensureChannel()
                    startInForeground(buildOngoingNotification())
                    handleStop()
                    return START_NOT_STICKY
                }
                ensureChannel()
                startInForeground(buildOngoingNotification())
                handleComplete(intent.getLongExtra(EXTRA_EXPECTED_DEADLINE, 0L))
            }
            ACTION_STOP -> {
                handleStop()
                return START_NOT_STICKY
            }
            ACTION_SKIP_BREAK -> {
                handleSkipBreak()
                return START_NOT_STICKY
            }
            ACTION_POSTPONE_BREAK -> {
                handlePostponeBreak()
                return START_NOT_STICKY
            }
            else -> {
                if (!restoreState()) {
                    handleStop()
                    return START_NOT_STICKY
                }
                ensureChannel()
                startInForeground(buildOngoingNotification())
                presentCurrentPhase()
                resumeCurrentPhase()
            }
        }
        return START_STICKY
    }

    private fun handleStart(intent: Intent) {
        deadlineMillis = intent.getLongExtra(EXTRA_DEADLINE, 0L)
        isBreak = intent.getBooleanExtra(EXTRA_IS_BREAK, false)
        breakMode = intent.getStringExtra(EXTRA_BREAK_MODE) ?: "gentle"
        workDurationSeconds = intent.getIntExtra(EXTRA_WORK_DURATION, 0)
        breakDurationSeconds = intent.getIntExtra(EXTRA_BREAK_DURATION, 0)
        longBreakEnabled = intent.getBooleanExtra(EXTRA_LONG_BREAK_ENABLED, false)
        longBreakDurationSeconds = intent.getIntExtra(EXTRA_LONG_BREAK_DURATION, 0)
        longBreakEveryCycles = intent.getIntExtra(EXTRA_LONG_BREAK_EVERY, 0)
        autoRunEnabled = intent.getBooleanExtra(EXTRA_AUTO_RUN_ENABLED, false)
        autoRunCycleLimit = intent.getIntExtra(EXTRA_AUTO_RUN_LIMIT, 0)
        streakCount = intent.getIntExtra(EXTRA_STREAK_COUNT, 0)
        completedAutoRunCycles = intent.getIntExtra(EXTRA_COMPLETED_AUTO_RUN_CYCLES, 0)
        allowSkip = intent.getBooleanExtra(EXTRA_ALLOW_SKIP, true)
        allowPostpone = intent.getBooleanExtra(EXTRA_ALLOW_POSTPONE, true)
        postponeDurationSeconds = intent.getIntExtra(EXTRA_POSTPONE_DURATION, 120)
        smartIdleEnabled = intent.getBooleanExtra(EXTRA_SMART_IDLE, true)
        naturalBreakCreditEnabled = intent.getBooleanExtra(EXTRA_NATURAL_BREAK_CREDIT, true)
        postponedBreakDuration = intent.getIntExtra("postponedBreakDuration", -1)
        currentPhaseInitialDuration = intent.getIntExtra("currentPhaseInitialDuration", if (isBreak) breakDurationForCompletedCycle(streakCount) else workDurationSeconds)
        maxConsecutiveSkips = intent.getIntExtra("maxConsecutiveSkips", 0)
        autoPostponeApps = intent.getStringExtra("autoPostponeApps") ?: ""
        osFocusDndEnabled = intent.getBooleanExtra("osFocusDndEnabled", false)

        ensureChannel()
        startInForeground(buildOngoingNotification())
        if (deadlineMillis <= 0L) {
            handleStop()
            return
        }

        saveState()
        resumeCurrentPhase()
    }

    private fun handleSkipBreak() {
        if (isBreak) {
            // Enforce consecutive skip limit
            if (maxConsecutiveSkips > 0 && consecutiveSkips >= maxConsecutiveSkips) {
                return // silently block — UI will already hide the button
            }
            consecutiveSkips++
            pendingEvents.add(mapOf(
                "type" to "breakSkipped",
                "timestamp" to System.currentTimeMillis(),
                "durationSeconds" to 0
            ))
            deadlineMillis = System.currentTimeMillis()
            handleComplete(deadlineMillis)
        }
    }

    private fun handlePostponeBreak() {
        if (isBreak) {
            BreakOverlayController.hide()
            isBreak = false
            postponedBreakDuration = currentPhaseInitialDuration
            currentPhaseInitialDuration = postponeDurationSeconds
            pendingEvents.add(mapOf(
                "type" to "breakPostponed",
                "timestamp" to System.currentTimeMillis(),
                "durationSeconds" to postponeDurationSeconds
            ))
            deadlineMillis = System.currentTimeMillis() + postponeDurationSeconds * 1000L
            saveState()
            presentCurrentPhase()
            resumeCurrentPhase()
        }
    }

    private fun isUsageAccessGranted(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? android.app.AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun getForegroundPackageName(context: Context): String? {
        if (!isUsageAccessGranted(context)) return null
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? android.app.usage.UsageStatsManager ?: return null
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(now - 10000, now) ?: return null
        val event = android.app.usage.UsageEvents.Event()
        var lastForegroundApp: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED) {
                lastForegroundApp = event.packageName
            }
        }
        return lastForegroundApp
    }

    private fun isGameOrVideoApp(context: Context, packageName: String): Boolean {
        val lowerPackage = packageName.lowercase()
        if (lowerPackage.contains("youtube") ||
            lowerPackage.contains("netflix") ||
            lowerPackage.contains("player") ||
            lowerPackage.contains("video") ||
            lowerPackage.contains("game")
        ) {
            return true
        }
        return try {
            val pm = context.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appInfo.category == android.content.pm.ApplicationInfo.CATEGORY_GAME ||
                appInfo.category == android.content.pm.ApplicationInfo.CATEGORY_VIDEO
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isUserImmersed(context: Context): Boolean {
        // 1. Check if screen is being shared/cast
        val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as? android.hardware.display.DisplayManager
        if (displayManager != null) {
            val displays = displayManager.displays
            if (displays.size > 1) {
                return true
            }
        }

        // 2. Check if a game or video app is in the foreground, or in autoPostponeApps
        val foregroundApp = getForegroundPackageName(context)
        if (foregroundApp != null && foregroundApp != context.packageName) {
            if (isGameOrVideoApp(context, foregroundApp)) {
                return true
            }
            if (autoPostponeApps.isNotEmpty()) {
                val apps = autoPostponeApps.split(",").map { it.trim().lowercase() }.filter { it.isNotEmpty() }
                val lowerForegroundApp = foregroundApp.lowercase()
                for (app in apps) {
                    if (lowerForegroundApp.contains(app)) {
                        return true
                    }
                }
            }
        }

        // 3. Check if device is in DND (Do Not Disturb) mode
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        if (notificationManager != null) {
            val filter = notificationManager.currentInterruptionFilter
            if (filter == NotificationManager.INTERRUPTION_FILTER_NONE ||
                filter == NotificationManager.INTERRUPTION_FILTER_ALARMS ||
                filter == NotificationManager.INTERRUPTION_FILTER_PRIORITY) {
                return true
            }
        }

        return false
    }

    fun handleComplete(expectedDeadline: Long) {
        if (expectedDeadline > 0L && expectedDeadline != deadlineMillis) {
            // A previous alarm was already queued when Flutter changed phase.
            resumeCurrentPhase()
            return
        }

        handler.removeCallbacks(tick)
        cancelExactAlarm()
        val now = System.currentTimeMillis()

        if (smartIdleEnabled && !isBreak && isUserImmersed(this)) {
            val postponeTime = postponeDurationSeconds * 1000L
            deadlineMillis = now + postponeTime
            saveState()

            pendingEvents.add(mapOf(
                "type" to "breakPostponed",
                "timestamp" to System.currentTimeMillis(),
                "durationSeconds" to postponeDurationSeconds
            ))

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val notification = baseBuilder()
                .setContentTitle("Eye break postponed")
                .setContentText("Postponed by ${postponeDurationSeconds / 60}m due to active game/video/cast.")
                .setOngoing(false)
                .setAutoCancel(true)
                .build()
            manager.notify(NOTIFICATION_ID, notification)

            presentCurrentPhase()
            resumeCurrentPhase()
            return
        }

        do {
            val completedWasBreak = isBreak
            if (!advanceBoundary()) {
                finishSchedule(completedWasBreak)
                return
            }
        } while (deadlineMillis <= now)

        saveState()
        presentCurrentPhase()
        resumeCurrentPhase()
    }

    /**
     * Advances exactly one boundary. The order mirrors Dart projectPhase:
     * work increments counters and starts a break; break checks the run limit
     * before starting the next work phase.
     */
    private fun advanceBoundary(): Boolean {
        if (isBreak) {
            BreakOverlayController.hide()
            // Break completed naturally — reset consecutive skip counter
            consecutiveSkips = 0
            if (!shouldContinueAutoRun() || workDurationSeconds <= 0) {
                return false
            }
            isBreak = false
            deadlineMillis += workDurationSeconds * 1000L
            currentPhaseInitialDuration = workDurationSeconds
            return true
        }

        val isPostponedTransition = postponedBreakDuration > 0
        val duration = if (isPostponedTransition) {
            val dur = postponedBreakDuration
            postponedBreakDuration = -1
            dur
        } else {
            streakCount += 1
            completedAutoRunCycles += 1
            breakDurationForCompletedCycle(streakCount)
        }

        if (duration <= 0) {
            return false
        }

        if (!isPostponedTransition) {
            pendingEvents.add(mapOf(
                "type" to "workCompleted",
                "timestamp" to System.currentTimeMillis(),
                "durationSeconds" to workDurationSeconds
            ))
        }

        isBreak = true
        deadlineMillis += duration * 1000L
        currentPhaseInitialDuration = duration
        return true
    }

    private fun shouldContinueAutoRun(): Boolean {
        return autoRunEnabled &&
            (autoRunCycleLimit <= 0 || completedAutoRunCycles < autoRunCycleLimit)
    }

    private fun breakDurationForCompletedCycle(completedCycles: Int): Int {
        if (!longBreakEnabled || longBreakEveryCycles <= 0) {
            return breakDurationSeconds
        }
        return if (completedCycles % longBreakEveryCycles == 0) {
            longBreakDurationSeconds
        } else {
            breakDurationSeconds
        }
    }

    fun presentCurrentPhase() {
        if (isBreak && breakMode != "off" && !AppVisibility.isActivityResumed) {
            val seconds = secondsRemaining().coerceAtLeast(1L).coerceAtMost(Int.MAX_VALUE.toLong())
            BreakOverlayController.show(
                context = this,
                durationSeconds = seconds.toInt(),
                mode = breakMode,
                preview = false,
                allowSkip = allowSkip,
                allowPostpone = allowPostpone,
                postponeDurationSeconds = postponeDurationSeconds
            )
        } else {
            BreakOverlayController.hide()
        }
    }

    fun resumeCurrentPhase() {
        handler.removeCallbacks(tick)
        if (deadlineMillis <= System.currentTimeMillis()) {
            handleComplete(deadlineMillis)
            return
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildOngoingNotification())
        scheduleExactAlarm(deadlineMillis)
        updateDndState()
        handler.post(tick)
    }

    private fun finishSchedule(completedWasBreak: Boolean) {
        handler.removeCallbacks(tick)
        cancelExactAlarm()
        BreakOverlayController.hide()
        clearState()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildCompletedNotification(completedWasBreak))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(false)
        }
        deadlineMillis = 0L
        updateDndState()
        stopSelf()
    }

    private fun handleStop() {
        handler.removeCallbacks(tick)
        cancelExactAlarm()
        BreakOverlayController.hide()
        clearState()
        deadlineMillis = 0L
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        deadlineMillis = 0L
        updateDndState()
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        activeService = null
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (_: Exception) {}
        deadlineMillis = 0L
        updateDndState()
        super.onDestroy()
    }

    private fun startInForeground(notification: Notification) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun secondsRemaining(): Long {
        val remainingMillis = deadlineMillis - System.currentTimeMillis()
        return if (remainingMillis <= 0L) 0L else (remainingMillis + 999L) / 1000L
    }

    private fun formatRemaining(totalSeconds: Long): String {
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return if (minutes > 0) {
            String.format("%02d:%02d", minutes, seconds)
        } else {
            "${seconds}s"
        }
    }

    private fun contentIntent(): PendingIntent {
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        } ?: Intent()
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, REQUEST_CONTENT, launch, flags)
    }

    private fun buildOngoingNotification(): Notification {
        val phase = if (isBreak) "Break time" else "Focus time"
        val builder = baseBuilder()
            .setContentTitle(phase)
            .setOngoing(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setUsesChronometer(true)
            builder.setChronometerCountDown(true)
            builder.setWhen(deadlineMillis)
            builder.setContentText("Countdown in progress")
        } else {
            builder.setUsesChronometer(false)
            builder.setContentText("${formatRemaining(secondsRemaining())} remaining")
        }
        return builder.build()
    }

    private fun buildCompletedNotification(completedWasBreak: Boolean): Notification {
        val title = if (completedWasBreak) "Break complete" else "Focus session complete"
        return baseBuilder()
            .setContentTitle(title)
            .setContentText("Tap to open BlinkKind.")
            .setOngoing(false)
            .setAutoCancel(true)
            .build()
    }

    private fun baseBuilder(): NotificationCompat.Builder {
        val smallIconId = resources.getIdentifier("ic_stat_eye", "drawable", packageName)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(if (smallIconId != 0) smallIconId else applicationInfo.icon)
            .setContentIntent(contentIntent())
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Timer status",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows the running BlinkKind work or break countdown."
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun alarmPendingIntent(): PendingIntent {
        val intent = Intent(this, PhaseDeadlineReceiver::class.java).apply {
            action = PhaseDeadlineReceiver.ACTION_FIRE
            putExtra(EXTRA_EXPECTED_DEADLINE, deadlineMillis)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(this, REQUEST_ALARM, intent, flags)
    }

    private fun scheduleExactAlarm(deadline: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val triggerElapsed = SystemClock.elapsedRealtime() +
            (deadline - System.currentTimeMillis()).coerceAtLeast(0L)
        val pending = alarmPendingIntent()
        try {
            val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager.canScheduleExactAlarms()
            } else {
                true
            }
            if (canExact) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerElapsed,
                    pending,
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerElapsed,
                    pending,
                )
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                triggerElapsed,
                pending,
            )
        }
    }

    private fun cancelExactAlarm() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(alarmPendingIntent())
    }

    private fun statePreferences(): SharedPreferences {
        return getSharedPreferences(STATE_PREFERENCES, Context.MODE_PRIVATE)
    }

    fun saveState() {
        statePreferences().edit()
            .putLong(EXTRA_DEADLINE, deadlineMillis)
            .putBoolean(EXTRA_IS_BREAK, isBreak)
            .putString(EXTRA_BREAK_MODE, breakMode)
            .putInt(EXTRA_WORK_DURATION, workDurationSeconds)
            .putInt(EXTRA_BREAK_DURATION, breakDurationSeconds)
            .putBoolean(EXTRA_LONG_BREAK_ENABLED, longBreakEnabled)
            .putInt(EXTRA_LONG_BREAK_DURATION, longBreakDurationSeconds)
            .putInt(EXTRA_LONG_BREAK_EVERY, longBreakEveryCycles)
            .putBoolean(EXTRA_AUTO_RUN_ENABLED, autoRunEnabled)
            .putInt(EXTRA_AUTO_RUN_LIMIT, autoRunCycleLimit)
            .putInt(EXTRA_STREAK_COUNT, streakCount)
            .putInt(EXTRA_COMPLETED_AUTO_RUN_CYCLES, completedAutoRunCycles)
            .putBoolean(EXTRA_ALLOW_SKIP, allowSkip)
            .putBoolean(EXTRA_ALLOW_POSTPONE, allowPostpone)
            .putInt(EXTRA_POSTPONE_DURATION, postponeDurationSeconds)
            .putBoolean("smartIdleEnabled", smartIdleEnabled)
            .putBoolean("naturalBreakCreditEnabled", naturalBreakCreditEnabled)
            .putInt("postponedBreakDuration", postponedBreakDuration)
            .putInt("currentPhaseInitialDuration", currentPhaseInitialDuration)
            .putLong("screenOffTimeMillis", screenOffTimeMillis)
            .putBoolean("isScreenOffPaused", isScreenOffPaused)
            .putLong("pausedRemainingSeconds", pausedRemainingSeconds)
            .putInt("maxConsecutiveSkips", maxConsecutiveSkips)
            .putInt("consecutiveSkips", consecutiveSkips)
            .putString("autoPostponeApps", autoPostponeApps)
            .putBoolean("osFocusDndEnabled", osFocusDndEnabled)
            .putLong("lastSavedAt", System.currentTimeMillis())
            .commit()
        TimerWidgetProvider.triggerUpdate(this)
    }

    private fun isSameDay(time1: Long, time2: Long): Boolean {
        val cal1 = java.util.Calendar.getInstance().apply { timeInMillis = time1 }
        val cal2 = java.util.Calendar.getInstance().apply { timeInMillis = time2 }
        return cal1.get(java.util.Calendar.YEAR) == cal2.get(java.util.Calendar.YEAR) &&
               cal1.get(java.util.Calendar.DAY_OF_YEAR) == cal2.get(java.util.Calendar.DAY_OF_YEAR)
    }

    private fun restoreState(): Boolean {
        val preferences = statePreferences()
        val lastSavedAt = preferences.getLong("lastSavedAt", 0L)
        val now = System.currentTimeMillis()
        if (lastSavedAt > 0L && !isSameDay(lastSavedAt, now)) {
            clearState()
            return false
        }
        isScreenOffPaused = preferences.getBoolean("isScreenOffPaused", false)
        pausedRemainingSeconds = preferences.getLong("pausedRemainingSeconds", 0L)
        deadlineMillis = preferences.getLong(EXTRA_DEADLINE, 0L)
        if (deadlineMillis <= 0L && !isScreenOffPaused) return false
        isBreak = preferences.getBoolean(EXTRA_IS_BREAK, false)
        breakMode = preferences.getString(EXTRA_BREAK_MODE, "gentle") ?: "gentle"
        workDurationSeconds = preferences.getInt(EXTRA_WORK_DURATION, 0)
        breakDurationSeconds = preferences.getInt(EXTRA_BREAK_DURATION, 0)
        longBreakEnabled = preferences.getBoolean(EXTRA_LONG_BREAK_ENABLED, false)
        longBreakDurationSeconds = preferences.getInt(EXTRA_LONG_BREAK_DURATION, 0)
        longBreakEveryCycles = preferences.getInt(EXTRA_LONG_BREAK_EVERY, 0)
        autoRunEnabled = preferences.getBoolean(EXTRA_AUTO_RUN_ENABLED, false)
        autoRunCycleLimit = preferences.getInt(EXTRA_AUTO_RUN_LIMIT, 0)
        streakCount = preferences.getInt(EXTRA_STREAK_COUNT, 0)
        completedAutoRunCycles = preferences.getInt(EXTRA_COMPLETED_AUTO_RUN_CYCLES, 0)
        allowSkip = preferences.getBoolean(EXTRA_ALLOW_SKIP, true)
        allowPostpone = preferences.getBoolean(EXTRA_ALLOW_POSTPONE, true)
        postponeDurationSeconds = preferences.getInt(EXTRA_POSTPONE_DURATION, 120)
        smartIdleEnabled = preferences.getBoolean("smartIdleEnabled", true)
        naturalBreakCreditEnabled = preferences.getBoolean("naturalBreakCreditEnabled", true)
        postponedBreakDuration = preferences.getInt("postponedBreakDuration", -1)
        currentPhaseInitialDuration = preferences.getInt("currentPhaseInitialDuration", 0)
        screenOffTimeMillis = preferences.getLong("screenOffTimeMillis", 0L)
        maxConsecutiveSkips = preferences.getInt("maxConsecutiveSkips", 0)
        consecutiveSkips = preferences.getInt("consecutiveSkips", 0)
        autoPostponeApps = preferences.getString("autoPostponeApps", "") ?: ""
        osFocusDndEnabled = preferences.getBoolean("osFocusDndEnabled", false)

        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        val isScreenOn = powerManager?.isInteractive ?: true
        if (isScreenOffPaused && isScreenOn) {
            isScreenOffPaused = false
            deadlineMillis = System.currentTimeMillis() + pausedRemainingSeconds * 1000L
        }
        return true
    }

    private fun updateDndState() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (manager != null && manager.isNotificationPolicyAccessGranted) {
                val shouldBeDnd = osFocusDndEnabled && !isBreak && deadlineMillis > 0L && !isScreenOffPaused
                val currentFilter = manager.currentInterruptionFilter
                if (shouldBeDnd) {
                    if (currentFilter != NotificationManager.INTERRUPTION_FILTER_PRIORITY) {
                        try {
                            manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                        } catch (e: SecurityException) {
                            // Ignore if permission was revoked
                        }
                    }
                } else {
                    if (currentFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
                        try {
                            manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                        } catch (e: SecurityException) {
                            // Ignore
                        }
                    }
                }
            }
        }
    }

    private fun clearState() {
        statePreferences().edit().clear().commit()
        TimerWidgetProvider.triggerUpdate(this)
    }

    companion object {
        const val ACTION_START = "com.jatin.eyecaretimer.action.START_PHASE"
        const val ACTION_STOP = "com.jatin.eyecaretimer.action.STOP_PHASE"
        const val ACTION_COMPLETE = "com.jatin.eyecaretimer.action.COMPLETE_PHASE"
        const val ACTION_SKIP_BREAK = "com.jatin.eyecaretimer.action.SKIP_BREAK"
        const val ACTION_POSTPONE_BREAK = "com.jatin.eyecaretimer.action.POSTPONE_BREAK"

        const val EXTRA_DEADLINE = "deadlineMillis"
        const val EXTRA_EXPECTED_DEADLINE = "expectedDeadlineMillis"
        const val EXTRA_IS_BREAK = "isBreak"
        const val EXTRA_BREAK_MODE = "breakMode"
        const val EXTRA_WORK_DURATION = "workDurationSeconds"
        const val EXTRA_BREAK_DURATION = "breakDurationSeconds"
        const val EXTRA_LONG_BREAK_ENABLED = "longBreakEnabled"
        const val EXTRA_LONG_BREAK_DURATION = "longBreakDurationSeconds"
        const val EXTRA_LONG_BREAK_EVERY = "longBreakEveryCycles"
        const val EXTRA_AUTO_RUN_ENABLED = "autoRunEnabled"
        const val EXTRA_AUTO_RUN_LIMIT = "autoRunCycleLimit"
        const val EXTRA_STREAK_COUNT = "streakCount"
        const val EXTRA_COMPLETED_AUTO_RUN_CYCLES = "completedAutoRunCycles"
        const val EXTRA_ALLOW_SKIP = "allowSkip"
        const val EXTRA_ALLOW_POSTPONE = "allowPostpone"
        const val EXTRA_POSTPONE_DURATION = "postponeDurationSeconds"
        const val EXTRA_SMART_IDLE = "smartIdleEnabled"
        const val EXTRA_NATURAL_BREAK_CREDIT = "naturalBreakCreditEnabled"

        private const val CHANNEL_ID = "blinkkind_timer_status"
        private const val NOTIFICATION_ID = 2001
        private const val REQUEST_CONTENT = 3001
        private const val REQUEST_ALARM = 3002
        private const val STATE_PREFERENCES = "blinkkind_timer_background_state"

        @Volatile
        var activeService: TimerForegroundService? = null

        fun start(
            context: Context,
            deadlineMillis: Long,
            isBreak: Boolean,
            breakMode: String,
            workDurationSeconds: Int,
            breakDurationSeconds: Int,
            longBreakEnabled: Boolean,
            longBreakDurationSeconds: Int,
            longBreakEveryCycles: Int,
            autoRunEnabled: Boolean,
            autoRunCycleLimit: Int,
            streakCount: Int,
            completedAutoRunCycles: Int,
            allowSkip: Boolean,
            allowPostpone: Boolean,
            postponeDurationSeconds: Int,
            smartIdleEnabled: Boolean,
            naturalBreakCreditEnabled: Boolean,
            postponedBreakDuration: Int? = null,
            currentPhaseDurationSeconds: Int? = null,
            maxConsecutiveSkips: Int = 0,
            autoPostponeApps: String = "",
            osFocusDndEnabled: Boolean = false,
        ) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_START
                putExtra("autoPostponeApps", autoPostponeApps)
                putExtra(EXTRA_DEADLINE, deadlineMillis)
                putExtra(EXTRA_IS_BREAK, isBreak)
                putExtra(EXTRA_BREAK_MODE, breakMode)
                putExtra(EXTRA_WORK_DURATION, workDurationSeconds)
                putExtra(EXTRA_BREAK_DURATION, breakDurationSeconds)
                putExtra(EXTRA_LONG_BREAK_ENABLED, longBreakEnabled)
                putExtra(EXTRA_LONG_BREAK_DURATION, longBreakDurationSeconds)
                putExtra(EXTRA_LONG_BREAK_EVERY, longBreakEveryCycles)
                putExtra(EXTRA_AUTO_RUN_ENABLED, autoRunEnabled)
                putExtra(EXTRA_AUTO_RUN_LIMIT, autoRunCycleLimit)
                putExtra(EXTRA_STREAK_COUNT, streakCount)
                putExtra(EXTRA_COMPLETED_AUTO_RUN_CYCLES, completedAutoRunCycles)
                putExtra(EXTRA_ALLOW_SKIP, allowSkip)
                putExtra(EXTRA_ALLOW_POSTPONE, allowPostpone)
                putExtra(EXTRA_POSTPONE_DURATION, postponeDurationSeconds)
                putExtra(EXTRA_SMART_IDLE, smartIdleEnabled)
                putExtra(EXTRA_NATURAL_BREAK_CREDIT, naturalBreakCreditEnabled)
                putExtra("postponedBreakDuration", postponedBreakDuration ?: -1)
                putExtra("maxConsecutiveSkips", maxConsecutiveSkips)
                putExtra("osFocusDndEnabled", osFocusDndEnabled)
                if (currentPhaseDurationSeconds != null) {
                    putExtra("currentPhaseInitialDuration", currentPhaseDurationSeconds)
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            try {
                context.startService(intent)
            } catch (_: Exception) {
                context.getSharedPreferences(STATE_PREFERENCES, Context.MODE_PRIVATE)
                    .edit()
                    .clear()
                    .apply()
                BreakOverlayController.hide()
            }
        }
    }
}
