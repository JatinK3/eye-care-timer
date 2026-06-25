package com.jatin.eyecaretimer

import android.app.AppOpsManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationSettingsChannel = "eye_care_timer/notification_settings"
    private val breakOverlayChannel = "blinkkind/break_overlay"
    private val timerBackgroundChannel = "blinkkind/timer_background"
    private val permissionsChannel = "blinkkind/permissions"
    private val reminderChannelId = "blinkkind_phase_reminders_v2"

    override fun onResume() {
        super.onResume()
        AppVisibility.isActivityResumed = true
    }

    override fun onPause() {
        AppVisibility.isActivityResumed = false
        super.onPause()
    }

    override fun onDestroy() {
        AppVisibility.isActivityResumed = false
        super.onDestroy()
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
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            breakOverlayChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
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
                else -> result.notImplemented()
            }
        }
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
