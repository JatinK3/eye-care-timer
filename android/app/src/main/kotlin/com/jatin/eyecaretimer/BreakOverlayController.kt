package com.jatin.eyecaretimer

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

object BreakOverlayController {
    private const val previewDurationSeconds = 10
    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var countdownText: TextView? = null
    private var remainingSeconds = previewDurationSeconds

    private val countdownRunnable = object : Runnable {
        override fun run() {
            remainingSeconds -= 1
            if (remainingSeconds <= 0) {
                hide()
                return
            }
            updateCountdown()
            handler.postDelayed(this, 1000)
        }
    }

    fun canDraw(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            Settings.canDrawOverlays(context)
    }

    fun showPreview(context: Context): Boolean {
        if (!canDraw(context)) return false
        hide()
        val appContext = context.applicationContext
        val manager = appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val root = buildOverlayView(appContext)
        val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            windowType,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.OPAQUE,
        ).apply {
            gravity = Gravity.FILL
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
        return try {
            manager.addView(root, params)
            windowManager = manager
            overlayView = root
            remainingSeconds = previewDurationSeconds
            updateCountdown()
            handler.postDelayed(countdownRunnable, 1000)
            true
        } catch (_: Exception) {
            windowManager = null
            overlayView = null
            countdownText = null
            false
        }
    }

    fun hide(): Boolean {
        handler.removeCallbacks(countdownRunnable)
        val view = overlayView
        val manager = windowManager
        overlayView = null
        windowManager = null
        countdownText = null
        if (view == null || manager == null) return false
        return try {
            manager.removeViewImmediate(view)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun buildOverlayView(context: Context): View {
        val density = context.resources.displayMetrics.density
        val root = FrameLayout(context).apply {
            setBackgroundColor(Color.BLACK)
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
            contentDescription = "BlinkKind break preview"
            systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((28 * density).toInt(), 24, (28 * density).toInt(), 24)
        }
        val title = TextView(context).apply {
            text = "Look 20 feet away"
            setTextColor(Color.WHITE)
            textSize = 28f
            gravity = Gravity.CENTER
        }
        countdownText = TextView(context).apply {
            setTextColor(Color.WHITE)
            textSize = 72f
            gravity = Gravity.CENTER
            setPadding(0, (20 * density).toInt(), 0, (12 * density).toInt())
            contentDescription = "Break preview countdown"
        }
        val instruction = TextView(context).apply {
            text = "Relax your focus and blink naturally."
            setTextColor(Color.LTGRAY)
            textSize = 17f
            gravity = Gravity.CENTER
        }
        val closeButton = Button(context).apply {
            text = "Close preview"
            contentDescription = "Close break preview"
            setOnClickListener { hide() }
        }
        content.addView(title)
        content.addView(countdownText)
        content.addView(instruction)
        content.addView(
            closeButton,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = (36 * density).toInt() },
        )
        root.addView(
            content,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        return root
    }

    private fun updateCountdown() {
        countdownText?.text = remainingSeconds.toString()
        countdownText?.contentDescription =
            "$remainingSeconds seconds remaining in break preview"
    }
}
