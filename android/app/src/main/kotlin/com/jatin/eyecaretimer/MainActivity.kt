package com.jatin.eyecaretimer

import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.content.Context
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationSettingsChannel = "eye_care_timer/notification_settings"
    private val breakOverlayChannel = "blinkkind/break_overlay"
    private val timerBackgroundChannel = "blinkkind/timer_background"
    private val permissionsChannel = "blinkkind/permissions"
    private val reminderChannelId = "blinkkind_phase_reminders_v2"

    // Kept so onPictureInPictureModeChanged can notify Dart to swap in/out the
    // compact PiP UI and keep _isMiniMode in sync with the OS PiP window state.
    private var breakOverlayMethodChannel: MethodChannel? = null

    private var isCameraActive = false
    private val cameraCallback = object : CameraManager.AvailabilityCallback() {
        private val activeCameras = mutableSetOf<String>()

        override fun onCameraAvailable(cameraId: String) {
            super.onCameraAvailable(cameraId)
            activeCameras.remove(cameraId)
            isCameraActive = activeCameras.isNotEmpty()
        }

        override fun onCameraUnavailable(cameraId: String) {
            super.onCameraUnavailable(cameraId)
            activeCameras.add(cameraId)
            isCameraActive = activeCameras.isNotEmpty()
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager
            cameraManager?.registerAvailabilityCallback(cameraCallback, null)
        } catch (e: Exception) {
            // Fallback for devices where camera service is unavailable
        }
    }

    override fun onResume() {
        super.onResume()
        AppVisibility.isActivityResumed = true
    }

    override fun onPause() {
        AppVisibility.isActivityResumed = false
        super.onPause()
    }

    override fun onDestroy() {
        try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager
            cameraManager?.unregisterAvailabilityCallback(cameraCallback)
        } catch (e: Exception) {
        }
        AppVisibility.isActivityResumed = false
        breakOverlayMethodChannel = null
        super.onDestroy()
    }

    private fun isMicInUse(): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        val isCallActive = audioManager.mode == AudioManager.MODE_IN_COMMUNICATION ||
                audioManager.mode == AudioManager.MODE_IN_CALL
        val isMicActive = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            audioManager.activeRecordingConfigurations.isNotEmpty()
        } else {
            false
        }
        return isMicActive || isCallActive
    }

    // --- Picture-in-Picture (Mini-Mode) ---------------------------------------
    // On Android the OS-native PiP window genuinely floats over other apps,
    // including fullscreen ones — unlike the desktop always-on-top window, which
    // a compositor may place below a fullscreen surface. See WORKLOG.md.

    private fun isPipSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun enterPipMode(): Boolean {
        // Inline SDK_INT guard (not the isPipSupported() helper) so lint's NewApi
        // check can prove the API-26 calls below are version-safe.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!packageManager.hasSystemFeature(
                PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
            return false
        }
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(1, 1))
                .build()
            enterPictureInPictureMode(params)
        } catch (e: Exception) {
            false
        }
    }

    // There is no direct "leave PiP" API; relaunching the activity in singleTop
    // reorders it to the front, which expands it out of the PiP window.
    private fun exitPipMode(): Boolean {
        return try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        breakOverlayMethodChannel?.invokeMethod(
            "onPipModeChanged",
            isInPictureInPictureMode,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationSettingsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> result.success(openNotificationSettings())
                "openReminderChannelSettings" -> result.success(openReminderChannelSettings())
                "isBatteryOptimizationIgnored" -> result.success(isBatteryOptimizationIgnored())
                "openBatteryOptimizationSettings" -> result.success(openBatteryOptimizationSettings())
                "requestIgnoreBatteryOptimizations" -> result.success(requestIgnoreBatteryOptimizations())
                "openOemBatterySettings" -> result.success(openOemBatterySettings())
                "detectOemManufacturer" -> result.success(Build.MANUFACTURER.lowercase())
                else -> result.notImplemented()
            }
        }
        val breakOverlay = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            breakOverlayChannel,
        )
        breakOverlayMethodChannel = breakOverlay
        breakOverlay.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" ->
                    result.success(isPipSupported())
                "enterPip" ->
                    result.success(enterPipMode())
                "exitPip" ->
                    result.success(exitPipMode())
                "overlayPermissionStatus" ->
                    result.success(BreakOverlayController.canDraw(this))
                "openOverlayPermissionSettings" ->
                    result.success(openOverlayPermissionSettings())
                "showOverlayPreview" ->
                    result.success(BreakOverlayController.showPreview(this))
                "stopOverlayPreview" ->
                    result.success(BreakOverlayController.hide())
                "showBreakOverlay" -> {
                    val duration = call.argument<Int>("durationSeconds") ?: 20
                    val mode = call.argument<String>("breakMode") ?: "gentle"
                    result.success(BreakOverlayController.show(this, duration, mode, false))
                }
                "stopBreakOverlay" ->
                    result.success(BreakOverlayController.hide())
                "isCameraInUse" ->
                    result.success(isCameraActive)
                "isMicInUse" ->
                    result.success(isMicInUse())
                "isMusicActive" -> {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                    result.success(audioManager?.isMusicActive ?: false)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            timerBackgroundChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPhase" -> {
                    val deadline =
                        (call.argument<Number>("phaseEndsAtMillis"))?.toLong() ?: 0L
                    if (deadline > 0L) {
                        TimerForegroundService.start(
                            context = this,
                            deadlineMillis = deadline,
                            isBreak = call.argument<Boolean>("isBreak") ?: false,
                            breakMode = call.argument<String>("breakMode") ?: "gentle",
                            workDurationSeconds =
                                call.argument<Int>("workDurationSeconds") ?: 0,
                            breakDurationSeconds =
                                call.argument<Int>("breakDurationSeconds") ?: 0,
                            longBreakEnabled =
                                call.argument<Boolean>("longBreakEnabled") ?: false,
                            longBreakDurationSeconds =
                                call.argument<Int>("longBreakDurationSeconds") ?: 0,
                            longBreakEveryCycles =
                                call.argument<Int>("longBreakEveryCycles") ?: 0,
                            autoRunEnabled =
                                call.argument<Boolean>("autoRunEnabled") ?: false,
                            autoRunCycleLimit =
                                call.argument<Int>("autoRunCycleLimit") ?: 0,
                            streakCount = call.argument<Int>("streakCount") ?: 0,
                            completedAutoRunCycles =
                                call.argument<Int>("completedAutoRunCycles") ?: 0,
                            allowSkip = call.argument<Boolean>("allowSkip") ?: true,
                            allowPostpone = call.argument<Boolean>("allowPostpone") ?: true,
                            postponeDurationSeconds = call.argument<Int>("postponeDurationSeconds") ?: 120,
                            smartIdleEnabled = call.argument<Boolean>("smartIdleEnabled") ?: true,
                            naturalBreakCreditEnabled = call.argument<Boolean>("naturalBreakCreditEnabled") ?: true,
                            osFocusDndEnabled = call.argument<Boolean>("osFocusDndEnabled") ?: false,
                            postponedBreakDuration = call.argument<Int>("postponedBreakDuration"),
                            currentPhaseDurationSeconds = call.argument<Int>("currentPhaseDurationSeconds"),
                        )
                    } else {
                        TimerForegroundService.stop(this)
                    }
                    result.success(true)
                }
                "stopPhase" -> {
                    TimerForegroundService.stop(this)
                    result.success(true)
                }
                "getBackgroundSession" -> {
                    val service = TimerForegroundService.activeService
                    if (service != null) {
                        val events = service.pendingEvents.toList()
                        service.pendingEvents.clear()
                        result.success(mapOf(
                            "isActive" to true,
                            "isBreak" to service.isBreak,
                            "phaseEndsAtMillis" to service.deadlineMillis,
                            "streakCount" to service.streakCount,
                            "completedAutoRunCycles" to service.completedAutoRunCycles,
                            "workDurationSeconds" to service.workDurationSeconds,
                            "breakDurationSeconds" to service.breakDurationSeconds,
                            "longBreakEnabled" to service.longBreakEnabled,
                            "longBreakDurationSeconds" to service.longBreakDurationSeconds,
                            "longBreakEveryCycles" to service.longBreakEveryCycles,
                            "autoRunEnabled" to service.autoRunEnabled,
                            "autoRunCycleLimit" to service.autoRunCycleLimit,
                            "pendingEvents" to events,
                            "postponedBreakDuration" to if (service.postponedBreakDuration > 0) service.postponedBreakDuration else null
                        ))
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            permissionsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "usageAccessPermissionStatus" ->
                    result.success(isUsageAccessGranted())
                "openUsageAccessSettings" ->
                    result.success(openUsageAccessSettings())
                "dndPermissionStatus" ->
                    result.success(isDndPermissionGranted())
                "openDndPermissionSettings" ->
                    result.success(openDndPermissionSettings())
                "setDndEnabled" -> {
                    val enabled = call.arguments as? Boolean ?: false
                    result.success(setDndEnabled(enabled))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isDndPermissionGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        return notificationManager?.isNotificationPolicyAccessGranted ?: true
    }

    private fun openDndPermissionSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return try {
            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun setDndEnabled(enabled: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
        if (notificationManager.isNotificationPolicyAccessGranted) {
            try {
                if (enabled) {
                    notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                } else {
                    notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                }
                return true
            } catch (e: SecurityException) {
                return false
            }
        }
        return false
    }

    private fun isUsageAccessGranted(): Boolean {
        val appOps = getSystemService(APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings(): Boolean {
        return try {
            startActivity(
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
            true
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun openOverlayPermissionSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return try {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName"),
                ),
            )
            true
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openBatteryOptimizationSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        return try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun requestIgnoreBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        return try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName")
                )
            )
            true
        } catch (_: Exception) {
            openBatteryOptimizationSettings()
        }
    }

    private fun openOemBatterySettings(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val oemIntents: List<() -> Intent> = when {
            manufacturer.contains("samsung") -> listOf(
                { Intent("com.samsung.android.sm.ACTION_BATTERY_SETTINGS") },
                { Intent("com.samsung.android.lool.ACTION_WHITELIST") }
            )
            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") -> listOf(
                {
                    Intent().setClassName(
                        "com.miui.powerkeeper",
                        "com.miui.powerkeeper.ui.HiddenAppsConfigActivity"
                    ).putExtra("package_name", packageName)
                        .putExtra("package_label", applicationInfo.loadLabel(packageManager))
                },
                { Intent("com.miui.powerkeeper.ACTION_IGNORE_BATTERY_OPTIMIZATION") }
            )
            manufacturer.contains("huawei") || manufacturer.contains("honor") -> listOf(
                {
                    Intent().setClassName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.optimize.process.ProtectActivity"
                    )
                }
            )
            manufacturer.contains("oppo") || manufacturer.contains("realme") || manufacturer.contains("coloros") -> listOf(
                {
                    Intent().setClassName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.permission.startupapp.StartupAppListActivity"
                    )
                },
                {
                    Intent().setClassName(
                        "com.oppo.safe",
                        "com.oppo.safe.permission.startup.StartupAppListActivity"
                    )
                }
            )
            manufacturer.contains("oneplus") -> listOf(
                { Intent("com.oneplus.security.chainlaunch.VIEW") }
            )
            manufacturer.contains("vivo") -> listOf(
                {
                    Intent().setClassName(
                        "com.vivo.permissionmanager",
                        "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                    )
                }
            )
            else -> emptyList()
        }
        for (intentFactory in oemIntents) {
            try {
                startActivity(intentFactory())
                return true
            } catch (_: Exception) {
                // try next
            }
        }
        // Fall back to the direct whitelist request or generic battery settings
        return requestIgnoreBatteryOptimizations()
    }

    private fun openReminderChannelSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return openNotificationSettings()
        }
        return try {
            startActivity(
                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    putExtra(Settings.EXTRA_CHANNEL_ID, reminderChannelId)
                },
            )
            true
        } catch (_: Exception) {
            openNotificationSettings()
        }
    }

    private fun openNotificationSettings(): Boolean {
        return try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                    },
                )
                true
            } catch (_: Exception) {
                false
            }
        }
    }
}
