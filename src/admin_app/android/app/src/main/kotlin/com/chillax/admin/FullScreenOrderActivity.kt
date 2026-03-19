package com.chillax.admin

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

/**
 * Full-screen activity that shows over the lock screen for urgent order reminders.
 * Similar to an incoming phone call — wakes the device and demands attention.
 *
 * Shows: order info + "View Orders" and "Dismiss" buttons.
 * Reads locale from SharedPreferences (app_locale) to localize button text.
 */
class FullScreenOrderActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show over lock screen and turn screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val title = intent.getStringExtra("title") ?: "Order Pending!"
        val body = intent.getStringExtra("body") ?: ""
        val orderId = intent.getStringExtra("orderId") ?: ""

        buildUI(title, body, orderId)
    }

    private fun getLocale(): String {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getString("flutter.app_locale", "en") ?: "en"
    }

    private fun buildUI(title: String, body: String, orderId: String) {
        val dp = resources.displayMetrics.density
        val isArabic = getLocale() == "ar"

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF18181B.toInt()) // zinc-900
            setPadding((32 * dp).toInt(), (80 * dp).toInt(), (32 * dp).toInt(), (48 * dp).toInt())
        }

        // Warning icon (amber circle with "!" drawn via Canvas)
        val iconSize = (72 * dp).toInt()
        val alertIcon = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                iconSize + (24 * dp).toInt()
            )
            setPadding(0, 0, 0, (24 * dp).toInt())

            val iconView = object : View(this@FullScreenOrderActivity) {
                private val circlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = 0xFFFBBF24.toInt() // amber-400
                    style = Paint.Style.FILL
                }
                private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = 0xFF18181B.toInt() // zinc-900
                    textSize = 40 * dp
                    typeface = Typeface.DEFAULT_BOLD
                    textAlign = Paint.Align.CENTER
                }

                override fun onDraw(canvas: Canvas) {
                    val cx = width / 2f
                    val cy = height / 2f
                    val radius = minOf(cx, cy)
                    canvas.drawCircle(cx, cy, radius, circlePaint)
                    canvas.drawText("!", cx, cy + textPaint.textSize * 0.35f, textPaint)
                }
            }

            val iconParams = FrameLayout.LayoutParams(iconSize, iconSize).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
            addView(iconView, iconParams)
        }

        // Title
        val titleView = TextView(this).apply {
            text = title
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            textAlignment = TextView.TEXT_ALIGNMENT_CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, (12 * dp).toInt())
        }

        // Body
        val bodyView = TextView(this).apply {
            text = body
            textSize = 16f
            setTextColor(0xFFA1A1AA.toInt()) // zinc-400
            textAlignment = TextView.TEXT_ALIGNMENT_CENTER
            setPadding(0, 0, 0, (48 * dp).toInt())
        }

        // Buttons container
        val buttonsLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, (16 * dp).toInt(), 0, 0)
        }

        val buttonLayoutParams = LinearLayout.LayoutParams(
            0, (52 * dp).toInt(), 1f
        ).apply {
            setMargins((8 * dp).toInt(), 0, (8 * dp).toInt(), 0)
        }

        // Dismiss button
        val dismissButton = Button(this).apply {
            text = if (isArabic) "تمام" else "Dismiss"
            setTextColor(0xFFFFFFFF.toInt())
            setBackgroundColor(0xFF3F3F46.toInt()) // zinc-700
            textSize = 16f
            isAllCaps = false
            layoutParams = buttonLayoutParams
            setOnClickListener {
                dismissNotification(orderId)
                finish()
            }
        }

        // View Orders button
        val viewButton = Button(this).apply {
            text = if (isArabic) "شوف الطلبات" else "View Orders"
            setTextColor(0xFF18181B.toInt()) // zinc-900
            setBackgroundColor(0xFFFFFFFF.toInt())
            textSize = 16f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            isAllCaps = false
            layoutParams = buttonLayoutParams
            setOnClickListener {
                dismissNotification(orderId)
                openOrders()
                finish()
            }
        }

        // RTL: swap button order for Arabic
        if (isArabic) {
            buttonsLayout.addView(viewButton)
            buttonsLayout.addView(dismissButton)
        } else {
            buttonsLayout.addView(dismissButton)
            buttonsLayout.addView(viewButton)
        }

        root.addView(alertIcon)
        root.addView(titleView)
        root.addView(bodyView)
        root.addView(buttonsLayout)

        setContentView(root)
    }

    private fun dismissNotification(orderId: String) {
        val notificationId = 5000 + (orderId.toIntOrNull() ?: 0)
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(notificationId)
    }

    private fun openOrders() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
        }
    }
}
