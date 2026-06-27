package com.jatin.eyecaretimer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import java.util.Locale

class TimerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE_WIDGET) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TimerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.jatin.eyecaretimer.action.UPDATE_WIDGET"
        private const val STATE_PREFERENCES = "blinkkind_timer_background_state"

        fun triggerUpdate(context: Context) {
            val intent = Intent(context, TimerWidgetProvider::class.java).apply {
                action = ACTION_UPDATE_WIDGET
            }
            context.sendBroadcast(intent)
        }

        private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.timer_widget)

            // Read preferences
            val prefs = context.getSharedPreferences(STATE_PREFERENCES, Context.MODE_PRIVATE)
            val deadlineMillis = prefs.getLong("deadlineMillis", 0L)
            val isBreak = prefs.getBoolean("isBreak", false)
            val isScreenOffPaused = prefs.getBoolean("isScreenOffPaused", false)
            val pausedRemainingSeconds = prefs.getLong("pausedRemainingSeconds", 0L)
            val allowSkip = prefs.getBoolean("allowSkip", true)
            val allowPostpone = prefs.getBoolean("allowPostpone", true)

            // Calculate remaining time
            val remainingSeconds = if (isScreenOffPaused) {
                pausedRemainingSeconds
            } else if (deadlineMillis > 0L) {
                val diff = (deadlineMillis - System.currentTimeMillis()) / 1000L
                if (diff < 0) 0L else diff
            } else {
                0L
            }

            // Format time as MM:SS
            val timeText = if (remainingSeconds > 0L) {
                val m = remainingSeconds / 60
                val s = remainingSeconds % 60
                String.format(Locale.getDefault(), "%02d:%02d", m, s)
            } else {
                "00:00"
            }
            views.setTextViewText(R.id.widget_time, timeText)

            // Set status label and colors
            if (deadlineMillis <= 0L && !isScreenOffPaused) {
                views.setTextViewText(R.id.widget_status, "Ready")
                views.setTextColor(R.id.widget_status, 0xFF888888.toInt()) // Gray
                views.setViewVisibility(R.id.widget_button_container, View.GONE)
            } else if (isScreenOffPaused) {
                views.setTextViewText(R.id.widget_status, "Paused")
                views.setTextColor(R.id.widget_status, 0xFFFFD54F.toInt()) // Yellow
                views.setViewVisibility(R.id.widget_button_container, View.GONE)
            } else if (isBreak) {
                views.setTextViewText(R.id.widget_status, "Break Phase")
                views.setTextColor(R.id.widget_status, 0xFFFF9800.toInt()) // Orange
                
                // Show actions during break
                views.setViewVisibility(R.id.widget_button_container, View.VISIBLE)
                views.setViewVisibility(R.id.widget_btn_skip, if (allowSkip) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.widget_btn_postpone, if (allowPostpone) View.VISIBLE else View.GONE)
            } else {
                views.setTextViewText(R.id.widget_status, "Work Phase")
                views.setTextColor(R.id.widget_status, 0xFF4CAF50.toInt()) // Green
                views.setViewVisibility(R.id.widget_button_container, View.GONE)
            }

            // Click pending intent for widget body (Open App)
            val openIntent = Intent(context, MainActivity::class.java)
            val pendingOpenIntent = PendingIntent.getActivity(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingOpenIntent)

            // Click pending intent for Skip Button
            val skipIntent = Intent(context, TimerForegroundService::class.java).apply {
                action = TimerForegroundService.ACTION_SKIP_BREAK
            }
            val pendingSkipIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(
                    context, 1, skipIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getService(
                    context, 1, skipIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }
            views.setOnClickPendingIntent(R.id.widget_btn_skip, pendingSkipIntent)

            // Click pending intent for Postpone Button
            val postponeIntent = Intent(context, TimerForegroundService::class.java).apply {
                action = TimerForegroundService.ACTION_POSTPONE_BREAK
            }
            val pendingPostponeIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(
                    context, 2, postponeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getService(
                    context, 2, postponeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }
            views.setOnClickPendingIntent(R.id.widget_btn_postpone, pendingPostponeIntent)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
