package com.jatin.eyecaretimer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Automatically restores the background service and exact alarms upon device reboot
 * or app package updates if a timer session was previously active.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            val prefs = context.getSharedPreferences("blinkkind_timer_background_state", Context.MODE_PRIVATE)
            val deadlineMillis = prefs.getLong("deadlineMillis", 0L)
            if (deadlineMillis > 0L) {
                val serviceIntent = Intent(context, TimerForegroundService::class.java)
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } catch (_: Exception) {
                    // System background restrictions or other failures during boot startup.
                }
            }
        }
    }
}
