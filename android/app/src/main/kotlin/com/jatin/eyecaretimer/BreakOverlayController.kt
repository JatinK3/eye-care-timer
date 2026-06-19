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
import android.widget.Toast
import kotlin.random.Random

object BreakOverlayController {
    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var countdownText: TextView? = null
    private var remainingSeconds = 20
    private var isPreview = false
    private var breakMode = "gentle"

    private val exercises = listOf(
        "Look 20 feet away at something green.",
        "Blink rapidly for 10 seconds to moisten your eyes.",
        "Roll your eyes slowly in a circle, then reverse.",
        "Close your eyes tightly and rest them.",
        "Focus on a distant object, then a near object."
    )

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
        return show(context, 10, "gentle", true)
    }

    fun show(context: Context, durationSeconds: Int, mode: String, preview: Boolean): Boolean {
        if (!canDraw(context)) return false
        hide()
        
        isPreview = preview
        breakMode = mode
        remainingSeconds = durationSeconds
        
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
            setBackgroundColor(Color.parseColor("#0F0F11")) // Deep elegant dark background
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
            contentDescription = "BlinkKind break screen"
            systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((32 * density).toInt(), 24, (32 * density).toInt(), 24)
        }
        
        val modeText = TextView(context).apply {
            text = when {
                isPreview -> "PREVIEW MODE"
                breakMode == "strict" -> "STRICT MODE"
                else -> "GENTLE MODE"
            }
            setTextColor(Color.parseColor("#8E8E93"))
            textSize = 12f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, (8 * density).toInt())
        }

        val title = TextView(context).apply {
            text = "Time to rest your eyes"
            setTextColor(Color.WHITE)
            textSize = 28f
            gravity = Gravity.CENTER
        }

        countdownText = TextView(context).apply {
            setTextColor(Color.parseColor("#64B5F6")) // Vibrant light blue color
            textSize = 84f
            gravity = Gravity.CENTER
            setPadding(0, (16 * density).toInt(), 0, (8 * density).toInt())
            contentDescription = "Break countdown"
        }

        val exerciseText = TextView(context).apply {
            val randomExercise = exercises[Random.nextInt(exercises.size)]
            text = randomExercise
            setTextColor(Color.parseColor("#E5E5EA"))
            textSize = 18f
            gravity = Gravity.CENTER
            setPadding(0, (8 * density).toInt(), 0, (24 * density).toInt())
        }

        content.addView(modeText)
        content.addView(title)
        content.addView(countdownText)
        content.addView(exerciseText)

        if (breakMode == "strict" && !isPreview) {
            val emergencyButton = Button(context).apply {
                text = "Emergency exit (Hold)"
                setTextColor(Color.parseColor("#FF453A")) // Elegant system red
                setBackgroundColor(Color.parseColor("#1C1C1E"))
                contentDescription = "Hold for emergency exit"
                setPadding((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (12 * density).toInt())
                
                setOnLongClickListener {
                    hide()
                    Toast.makeText(context, "Emergency exit triggered", Toast.LENGTH_SHORT).show()
                    true
                }
                setOnClickListener {
                    Toast.makeText(context, "Press and hold button to force exit", Toast.LENGTH_SHORT).show()
                }
            }
            content.addView(
                emergencyButton,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = (24 * density).toInt() }
            )
        } else {
            val skipButton = Button(context).apply {
                text = if (isPreview) "Close preview" else "Skip break"
                setTextColor(Color.parseColor("#30D158")) // Elegant green color
                setBackgroundColor(Color.parseColor("#1C1C1E"))
                contentDescription = if (isPreview) "Close preview" else "Skip break"
                setPadding((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (12 * density).toInt())
                setOnClickListener { hide() }
            }
            content.addView(
                skipButton,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = (24 * density).toInt() }
            )
        }

        root.addView(
            content,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )
        return root
    }

    private fun updateCountdown() {
        countdownText?.text = remainingSeconds.toString()
        countdownText?.contentDescription =
            "$remainingSeconds seconds remaining in break"
    }
}
