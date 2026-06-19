package com.jatin.eyecaretimer

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat

/**
 * Foreground service that owns the active timer phase deadline while BlinkKind
 * is backgrounded or the screen is locked.
 *
 * The Flutter side remains the single source of truth for phase logic; this
 * service just mirrors the current absolute deadline so the OS keeps the
 * process alive, shows an ongoing countdown notification, and fires an exact
 * alarm at the deadline. The audible phase-complete cue is still delivered by
 * flutter_local_notifications, so this service's notifications stay silent to
 * avoid double alerts.
 */
class TimerForegroundService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var deadlineMillis: Long = 0L
    private var isBreak: Boolean = false
    private var completed: Boolean = false

    private val tick = object : Runnable {
        override fun run() {
            updateOngoingNotification()
            handler.postDelayed(this, 1000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_COMPLETE -> handleComplete()
            ACTION_STOP -> handleStop()
            else -> handleStop()
        }
        return START_NOT_STICKY
    }

    private fun handleStart(intent: Intent) {
        deadlineMillis = intent.getLongExtra(EXTRA_DEADLINE, 0L)
        isBreak = intent.getBooleanExtra(EXTRA_IS_BREAK, false)
        completed = false
        // Always enter the foreground before any early return: a service started
        // with startForegroundService() must call startForeground() promptly.
        ensureChannel()
        startInForeground(buildOngoingNotification())
        if (deadlineMillis <= 0L) {
            handleStop()
            return
        }
        handler.removeCallbacks(tick)
        handler.post(tick)
        scheduleExactAlarm(deadlineMillis)
    }

    private fun handleComplete() {
        completed = true
        handler.removeCallbacks(tick)
        cancelExactAlarm()
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildCompletedNotification())
        // Detach the notification so it remains tappable, then stop the service.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            @Suppress("DEPRECATION")
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(false)
        }
        stopSelf()
    }

    private fun handleStop() {
        completed = true
        handler.removeCallbacks(tick)
        cancelExactAlarm()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    private fun startInForeground(notification: Notification) {
        try {
            // Only API 34+ requires (and enforces) an explicit foreground
            // service type at call time; the plain overload is correct below it.
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
            // If the platform refuses the foreground start (e.g. missing type),
            // fall back to a plain notification so we never crash the app.
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

    private fun updateOngoingNotification() {
        if (completed) return
        if (secondsRemaining() <= 0L) {
            // The handler may briefly outrun the alarm; reflect completion.
            handleComplete()
            return
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildOngoingNotification())
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
        return baseBuilder()
            .setContentTitle(phase)
            .setContentText("${formatRemaining(secondsRemaining())} remaining")
            .setOngoing(true)
            .setUsesChronometer(false)
            .build()
    }

    private fun buildCompletedNotification(): Notification {
        val title = if (isBreak) "Break complete" else "Focus session complete"
        return baseBuilder()
            .setContentTitle(title)
            .setContentText("Tap to open BlinkKind.")
            .setOngoing(false)
            .setAutoCancel(true)
            .build()
    }

    private fun baseBuilder(): NotificationCompat.Builder {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
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
            putExtra(EXTRA_IS_BREAK, isBreak)
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

    companion object {
        const val ACTION_START = "com.jatin.eyecaretimer.action.START_PHASE"
        const val ACTION_STOP = "com.jatin.eyecaretimer.action.STOP_PHASE"
        const val ACTION_COMPLETE = "com.jatin.eyecaretimer.action.COMPLETE_PHASE"
        const val EXTRA_DEADLINE = "deadlineMillis"
        const val EXTRA_IS_BREAK = "isBreak"

        private const val CHANNEL_ID = "blinkkind_timer_status"
        private const val NOTIFICATION_ID = 2001
        private const val REQUEST_CONTENT = 3001
        private const val REQUEST_ALARM = 3002

        fun start(context: Context, deadlineMillis: Long, isBreak: Boolean) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_DEADLINE, deadlineMillis)
                putExtra(EXTRA_IS_BREAK, isBreak)
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
                // Service not running; nothing to stop.
            }
        }
    }
}
