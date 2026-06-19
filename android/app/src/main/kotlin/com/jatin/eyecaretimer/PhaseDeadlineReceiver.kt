package com.jatin.eyecaretimer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Delivers an exact phase deadline to the native cadence owner. The expected
 * deadline lets the service ignore a stale broadcast after Flutter has already
 * changed, paused, or replaced the active phase.
 */
class PhaseDeadlineReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val expectedDeadline = intent?.getLongExtra(
            TimerForegroundService.EXTRA_EXPECTED_DEADLINE,
            0L,
        ) ?: 0L
        val complete = Intent(context, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_COMPLETE
            putExtra(TimerForegroundService.EXTRA_EXPECTED_DEADLINE, expectedDeadline)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(complete)
            } else {
                context.startService(complete)
            }
        } catch (_: Exception) {
            // Force-stop and platform background restrictions cannot be bypassed.
        }
    }

    companion object {
        const val ACTION_FIRE = "com.jatin.eyecaretimer.action.PHASE_DEADLINE"
    }
}
