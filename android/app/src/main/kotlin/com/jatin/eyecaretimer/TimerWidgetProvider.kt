package com.jatin.eyecaretimer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
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

        private fun drawProgressRing(context: Context, progress: Float, color: Int): Bitmap {
            val density = context.resources.displayMetrics.density
            val size = (64 * density).toInt() // 64dp size in pixels
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            
            val strokeWidth = 3 * density // 3dp stroke
            val radius = (size / 2f) - strokeWidth
            val rect = RectF(strokeWidth, strokeWidth, size.toFloat() - strokeWidth, size.toFloat() - strokeWidth)
            
            // Draw background track circle
            val bgPaint = Paint().apply {
                isAntiAlias = true
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                this.color = 0x14FFFFFF // Faint white (8% opacity)
            }
            canvas.drawCircle(size / 2f, size / 2f, radius, bgPaint)
            
            // Draw progress arc
            if (progress > 0f) {
                val progressPaint = Paint().apply {
                    isAntiAlias = true
                    style = Paint.Style.STROKE
                    this.strokeWidth = strokeWidth
                    this.color = color
                    strokeCap = Paint.Cap.ROUND
                }
                val sweepAngle = progress * 360f
                canvas.drawArc(rect, -90f, sweepAngle, false, progressPaint)
            }
            
            return bitmap
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
            val currentPhaseInitialDuration = prefs.getInt("currentPhaseInitialDuration", 0)

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

            // Calculate progress value
            val totalDuration = if (currentPhaseInitialDuration > 0) currentPhaseInitialDuration.toLong() else 1L
            val progress = if (deadlineMillis > 0L || isScreenOffPaused) {
                (remainingSeconds.toFloat() / totalDuration.toFloat()).coerceIn(0f, 1f)
            } else {
                0f
            }

            // Set status label and colors
            val progressColor: Int
            if (deadlineMillis <= 0L && !isScreenOffPaused) {
                views.setTextViewText(R.id.widget_status, "Ready")
                views.setTextColor(R.id.widget_status, 0xFF888888.toInt()) // Gray
                views.setViewVisibility(R.id.widget_button_container, View.GONE)
                progressColor = 0xFF888888.toInt()
            } else if (isScreenOffPaused) {
                views.setTextViewText(R.id.widget_status, "Paused")
                views.setTextColor(R.id.widget_status, 0xFFFFD54F.toInt()) // Yellow
                views.setViewVisibility(R.id.widget_button_container, View.GONE)
                progressColor = 0xFFFFD54F.toInt()
            } else if (isBreak) {
                views.setTextViewText(R.id.widget_status, "Break")
                views.setTextColor(R.id.widget_status, 0xFFFF9800.toInt()) // Orange
                
                // Show actions during break
                views.setViewVisibility(R.id.widget_button_container, View.VISIBLE)
                views.setViewVisibility(R.id.widget_btn_skip, if (allowSkip) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.widget_btn_postpone, if (allowPostpone) View.VISIBLE else View.GONE)
                progressColor = 0xFFFF9800.toInt()
            } else {
                views.setTextViewText(R.id.widget_status, "Work")
                views.setTextColor(R.id.widget_status, 0xFF4CAF50.toInt()) // Green
                views.setViewVisibility(R.id.widget_button_container, View.GONE)
                progressColor = 0xFF4CAF50.toInt()
            }

            // Draw and set the progress ring Bitmap
            val progressBitmap = drawProgressRing(context, progress, progressColor)
            views.setImageViewBitmap(R.id.widget_progress_ring, progressBitmap)

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
