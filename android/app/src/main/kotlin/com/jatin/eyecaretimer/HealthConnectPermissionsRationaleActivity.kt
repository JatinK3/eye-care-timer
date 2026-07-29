package com.jatin.eyecaretimer

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/// Required by Health Connect's debug permission flow. This component is
/// declared only in the debug manifest; Phase 1 will replace this copy with
/// BlinkKind's production privacy-policy rationale.
class HealthConnectPermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val padding = (24 * resources.displayMetrics.density).toInt()
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(padding, padding, padding, padding)
        }
        content.addView(TextView(this).apply {
            text = "Health Connect validation"
            textSize = 22f
        })
        content.addView(TextView(this).apply {
            text = "This debug build requests permission only to validate that manually logged water intake can be written to Health Connect. No data is read, shared, or used outside this emulator validation."
            textSize = 16f
            setPadding(0, padding, 0, padding)
        })
        content.addView(Button(this).apply {
            text = "Close"
            setOnClickListener { finish() }
        })
        setContentView(content)
    }
}
