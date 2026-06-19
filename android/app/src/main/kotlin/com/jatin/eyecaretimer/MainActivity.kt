package com.jatin.eyecaretimer

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationSettingsChannel = "eye_care_timer/notification_settings"
    private val breakOverlayChannel = "blinkkind/break_overlay"
    private val timerBackgroundChannel = "blinkkind/timer_background"
    private val reminderChannelId = "blinkkind_phase_reminders_v2"

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
                    val deadline = (call.argument<Number>("phaseEndsAtMillis"))?.toLong() ?: 0L
                    val isBreak = call.argument<Boolean>("isBreak") ?: false
                    val breakMode = call.argument<String>("breakMode") ?: "gentle"
                    val nextBreakDurationSeconds = call.argument<Int>("nextBreakDurationSeconds") ?: 0
                    if (deadline > 0L) {
                        TimerForegroundService.start(this, deadline, isBreak, breakMode, nextBreakDurationSeconds)
                    } else {
                        TimerForegroundService.stop(this)
                    }
                    result.success(true)
                }
                "stopPhase" -> {
                    TimerForegroundService.stop(this)
                    result.success(true)
                }
                else -> result.notImplemented()
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
