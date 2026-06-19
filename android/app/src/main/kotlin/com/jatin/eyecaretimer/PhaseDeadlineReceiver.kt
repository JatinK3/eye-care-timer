package com.jatin.eyecaretimer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fires when the exact alarm armed by [TimerForegroundService] reaches the
 * phase deadline (including while the device is in Doze). It hands control
 * back to the service so the ongoing countdown notification flips to a
 * tappable "phase complete" state. The audible cue itself is owned by
 * flutter_local_notifications, so this stays silent.
 */
class PhaseDeadlineReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val isBreak = intent?.getBooleanExtra(
            TimerForegroundService.EXTRA_IS_BREAK,
            false,
        ) ?: false
        val complete = Intent(context, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_COMPLETE
            putExtra(TimerForegroundService.EXTRA_IS_BREAK, isBreak)
        }
        try {
            // The service is already running in the foreground, so delivering a
            // command to it is permitted even from a background broadcast.
            context.startService(complete)
        } catch (_: Exception) {
            // If the service is gone, there is nothing left to update.
        }
    }

    companion object {
        const val ACTION_FIRE = "com.jatin.eyecaretimer.action.PHASE_DEADLINE"
    }
}
