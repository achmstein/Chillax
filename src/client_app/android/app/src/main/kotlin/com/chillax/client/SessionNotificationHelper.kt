package com.chillax.client

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class SessionNotificationHelper(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    companion object {
        const val NOTIFICATION_ID = 9001
        const val CHANNEL_ID = "session_controls_channel"
        const val CHANNEL_NAME = "com.chillax.client/session_notification"

        const val ACTION_CALL_WAITER = "com.chillax.client.ACTION_CALL_WAITER"
        const val ACTION_CONTROLLER = "com.chillax.client.ACTION_CONTROLLER"
        const val ACTION_SWITCH_MODE = "com.chillax.client.ACTION_SWITCH_MODE"

        const val COOLDOWN_MS = 30_000L

        // Shared state for cooldowns and notification refresh
        var instance: SessionNotificationHelper? = null
        val cooldowns = mutableMapOf<String, Long>() // action -> expiry timestamp
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastRoomName = ""
    private var lastDuration = ""
    private var lastStartTimeMs: Long? = null
    private var lastLocale = "en"
    private var lastPlayerMode = "Single"
    private var serviceStarted = false

    init {
        instance = this
    }

    fun show(roomName: String, duration: String, startTimeMs: Long?, locale: String, playerMode: String = "Single") {
        lastRoomName = roomName
        lastDuration = duration
        lastStartTimeMs = startTimeMs
        lastLocale = locale
        lastPlayerMode = playerMode

        if (!serviceStarted) {
            // First time — start foreground service
            SessionForegroundService.start(context, roomName, duration, startTimeMs, locale, playerMode)
            serviceStarted = true
        } else {
            // Update existing notification
            val notification = buildNotification(roomName, duration, startTimeMs, locale, playerMode)
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    fun buildNotification(roomName: String, duration: String, startTimeMs: Long?, locale: String, playerMode: String): Notification {
        val isArabic = locale == "ar"

        val openIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            putExtra("navigate_to", "/rooms")
        }
        val openPendingIntent = PendingIntent.getActivity(
            context, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val waiterPending = createActionPendingIntent(ACTION_CALL_WAITER, 1)
        val controllerPending = createActionPendingIntent(ACTION_CONTROLLER, 2)
        val switchModePending = createActionPendingIntent(ACTION_SWITCH_MODE, 3)

        val now = System.currentTimeMillis()

        val waiterLabel = getButtonLabel(ACTION_CALL_WAITER, if (isArabic) "الويتر" else "Waiter", now)
        val controllerLabel = getButtonLabel(ACTION_CONTROLLER, if (isArabic) "دراع" else "Controller", now)
        val switchModeLabel = getButtonLabel(ACTION_SWITCH_MODE,
            if (playerMode == "Multi") {
                if (isArabic) "سنجل" else "Single"
            } else {
                if (isArabic) "مالتي" else "Multi"
            }, now)

        val chronometerBase = if (startTimeMs != null) {
            SystemClock.elapsedRealtime() - (System.currentTimeMillis() - startTimeMs)
        } else {
            SystemClock.elapsedRealtime()
        }

        val expandedView = RemoteViews(context.packageName, R.layout.notification_session_expanded).apply {
            setTextViewText(R.id.room_name, roomName)
            setTextViewText(R.id.label_waiter, waiterLabel)
            setTextViewText(R.id.label_controller, controllerLabel)
            setTextViewText(R.id.label_switch_mode, switchModeLabel)
            setChronometer(R.id.chronometer, chronometerBase, null, true)
            setOnClickPendingIntent(R.id.btn_waiter, waiterPending)
            setOnClickPendingIntent(R.id.btn_controller, controllerPending)
            setOnClickPendingIntent(R.id.btn_switch_mode, switchModePending)
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(roomName)
            .setContentText(duration)
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSilent(true)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCustomBigContentView(expandedView)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)

        if (startTimeMs != null) {
            builder.setWhen(startTimeMs)
        }

        return builder.build()
    }

    fun dismiss() {
        if (serviceStarted) {
            SessionForegroundService.stop(context)
            serviceStarted = false
        }
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
        cooldowns.clear()
        instance = null
    }

    /** Refresh the notification to update cooldown labels */
    fun refresh() {
        show(lastRoomName, lastDuration, lastStartTimeMs, lastLocale, lastPlayerMode)
    }

    /** Handle an action: check cooldown, show feedback, forward to Flutter */
    fun handleAction(action: String) {
        val now = System.currentTimeMillis()
        val expiry = cooldowns[action] ?: 0L

        if (now < expiry) return // still in cooldown

        // Start cooldown
        cooldowns[action] = now + COOLDOWN_MS

        // Map to Dart action ID
        val actionId = when (action) {
            ACTION_CALL_WAITER -> "call_waiter"
            ACTION_CONTROLLER -> "controller"
            ACTION_SWITCH_MODE -> if (lastPlayerMode == "Multi") "switch_to_single" else "switch_to_multi"
            else -> return
        }

        // Forward to Flutter
        MainActivity.sessionChannel?.invokeMethod("onAction", actionId)

        // Refresh notification immediately to show feedback
        refresh()

        // Schedule periodic refreshes to update countdown labels
        scheduleCooldownUpdates()
    }

    private fun scheduleCooldownUpdates() {
        // Update every second while any cooldown is active
        handler.postDelayed(object : Runnable {
            override fun run() {
                val now = System.currentTimeMillis()
                val hasActiveCooldown = cooldowns.any { now < it.value }
                if (hasActiveCooldown) {
                    refresh()
                    handler.postDelayed(this, 1000)
                } else {
                    // Final refresh to restore original labels
                    refresh()
                }
            }
        }, 1000)
    }

    private fun getButtonLabel(action: String, originalLabel: String, now: Long): String {
        val expiry = cooldowns[action] ?: 0L
        if (now >= expiry) return originalLabel

        val remainingSeconds = ((expiry - now) / 1000).toInt()
        return "✓ ${remainingSeconds}s"
    }

    private fun createActionPendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, SessionActionReceiver::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}

class SessionActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        SessionNotificationHelper.instance?.handleAction(action)
    }
}
