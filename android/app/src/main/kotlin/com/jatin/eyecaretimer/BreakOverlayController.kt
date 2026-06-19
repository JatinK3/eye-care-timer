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
    private var allowSkip = true
    private var allowPostpone = true
    private var postponeDurationSeconds = 120

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

    fun show(
        context: Context,
        durationSeconds: Int,
        mode: String,
        preview: Boolean,
        allowSkip: Boolean = true,
        allowPostpone: Boolean = true,
        postponeDurationSeconds: Int = 120
    ): Boolean {
        if (!canDraw(context)) return false
        hide()
        
        isPreview = preview
        breakMode = mode
        remainingSeconds = durationSeconds
        this.allowSkip = allowSkip
        this.allowPostpone = allowPostpone
        this.postponeDurationSeconds = postponeDurationSeconds
        
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

    private fun triggerSkip(context: Context) {
        if (!isPreview) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = TimerForegroundService.ACTION_SKIP_BREAK
            }
            try {
                context.startService(intent)
            } catch (_: Exception) {
                TimerForegroundService.activeService?.let { service ->
                    service.deadlineMillis = System.currentTimeMillis()
                    service.handleComplete(service.deadlineMillis)
                }
            }
        }
        hide()
    }

    private fun triggerPostpone(context: Context) {
        if (!isPreview) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = TimerForegroundService.ACTION_POSTPONE_BREAK
            }
            try {
                context.startService(intent)
            } catch (_: Exception) {
                TimerForegroundService.activeService?.let { service ->
                    hide()
                    service.isBreak = false
                    service.deadlineMillis = System.currentTimeMillis() + service.postponeDurationSeconds * 1000L
                    service.saveState()
                    service.presentCurrentPhase()
                    service.resumeCurrentPhase()
                }
            }
        } else {
            hide()
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
                    triggerSkip(context)
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
        } else if (isPreview) {
            val skipButton = Button(context).apply {
                text = "Close preview"
                setTextColor(Color.parseColor("#30D158")) // Elegant green color
                setBackgroundColor(Color.parseColor("#1C1C1E"))
                contentDescription = "Close preview"
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
        } else {
            val buttonsContainer = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
            }
            
            if (allowSkip) {
                val skipButton = Button(context).apply {
                    text = "Skip break"
                    setTextColor(Color.parseColor("#30D158")) // Elegant green color
                    setBackgroundColor(Color.parseColor("#1C1C1E"))
                    contentDescription = "Skip break"
                    setPadding((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (12 * density).toInt())
                    setOnClickListener { triggerSkip(context) }
                }
                buttonsContainer.addView(skipButton)
            }
            
            if (allowPostpone) {
                if (allowSkip) {
                    buttonsContainer.addView(View(context).apply {
                        layoutParams = LinearLayout.LayoutParams((16 * density).toInt(), 1)
                    })
                }
                
                val postponeButton = Button(context).apply {
                    text = "Postpone (${postponeDurationSeconds / 60}m)"
                    setTextColor(Color.parseColor("#FF9F0A")) // Elegant orange color
                    setBackgroundColor(Color.parseColor("#1C1C1E"))
                    contentDescription = "Postpone break"
                    setPadding((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (12 * density).toInt())
                    setOnClickListener { triggerPostpone(context) }
                }
                buttonsContainer.addView(postponeButton)
            }
            
            content.addView(
                buttonsContainer,
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
