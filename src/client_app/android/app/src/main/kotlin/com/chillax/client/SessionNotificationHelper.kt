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
import android.view.View
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
        const val ACTION_ORDER_DRINK_1 = "com.chillax.client.ACTION_ORDER_DRINK_1"
        const val ACTION_ORDER_DRINK_2 = "com.chillax.client.ACTION_ORDER_DRINK_2"

        const val COOLDOWN_MS = 30_000L

        var instance: SessionNotificationHelper? = null
        val cooldowns = mutableMapOf<String, Long>()
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastRoomName = ""
    private var lastDuration = ""
    private var lastStartTimeMs: Long? = null
    private var lastLocale = "en"
    private var lastDrink1Id: Int? = null
    private var lastDrink1Name: String? = null
    private var lastDrink2Id: Int? = null
    private var lastDrink2Name: String? = null
    private var serviceStarted = false

    init {
        instance = this
    }

    fun show(
        roomName: String, duration: String, startTimeMs: Long?, locale: String,
        drink1Id: Int? = null, drink1Name: String? = null,
        drink2Id: Int? = null, drink2Name: String? = null
    ) {
        instance = this
        lastRoomName = roomName
        lastDuration = duration
        lastStartTimeMs = startTimeMs
        lastLocale = locale
        lastDrink1Id = drink1Id
        lastDrink1Name = drink1Name
        lastDrink2Id = drink2Id
        lastDrink2Name = drink2Name

        if (!serviceStarted) {
            try {
                SessionForegroundService.start(context, roomName, duration, startTimeMs, locale,
                    drink1Id, drink1Name, drink2Id, drink2Name)
                serviceStarted = true
            } catch (_: Exception) {
            }
        } else {
            val notification = buildNotification(roomName, duration, startTimeMs, locale,
                drink1Id, drink1Name, drink2Id, drink2Name)
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    fun buildNotification(
        roomName: String, duration: String, startTimeMs: Long?, locale: String,
        drink1Id: Int? = null, drink1Name: String? = null,
        drink2Id: Int? = null, drink2Name: String? = null
    ): Notification {
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
        val drink1Pending = createActionPendingIntent(ACTION_ORDER_DRINK_1, 3)
        val drink2Pending = createActionPendingIntent(ACTION_ORDER_DRINK_2, 4)

        val now = System.currentTimeMillis()

        val waiterLabel = getButtonLabel(ACTION_CALL_WAITER, if (isArabic) "الويتر" else "Waiter", now)
        val controllerLabel = getButtonLabel(ACTION_CONTROLLER, if (isArabic) "دراع" else "Controller", now)

        val chronometerBase = if (startTimeMs != null) {
            SystemClock.elapsedRealtime() - (System.currentTimeMillis() - startTimeMs)
        } else {
            SystemClock.elapsedRealtime()
        }

        val expandedView = RemoteViews(context.packageName, R.layout.notification_session_expanded).apply {
            setTextViewText(R.id.room_name, roomName)
            setTextViewText(R.id.label_waiter, waiterLabel)
            setTextViewText(R.id.label_controller, controllerLabel)
            setChronometer(R.id.chronometer, chronometerBase, null, true)
            setOnClickPendingIntent(R.id.btn_waiter, waiterPending)
            setOnClickPendingIntent(R.id.btn_controller, controllerPending)

            if (drink1Name != null) {
                setViewVisibility(R.id.btn_drink_1, View.VISIBLE)
                setTextViewText(R.id.label_drink_1, getButtonLabel(ACTION_ORDER_DRINK_1, drink1Name, now))
                setOnClickPendingIntent(R.id.btn_drink_1, drink1Pending)
            } else {
                setViewVisibility(R.id.btn_drink_1, View.GONE)
            }

            if (drink2Name != null) {
                setViewVisibility(R.id.btn_drink_2, View.VISIBLE)
                setTextViewText(R.id.label_drink_2, getButtonLabel(ACTION_ORDER_DRINK_2, drink2Name, now))
                setOnClickPendingIntent(R.id.btn_drink_2, drink2Pending)
            } else {
                setViewVisibility(R.id.btn_drink_2, View.GONE)
            }
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Chillax")
            .setContentText(roomName)
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
        // Do NOT null out instance — the BroadcastReceiver needs it for
        // future actions if show() is called again before a restart.
    }

    fun refresh() {
        show(lastRoomName, lastDuration, lastStartTimeMs, lastLocale,
            lastDrink1Id, lastDrink1Name, lastDrink2Id, lastDrink2Name)
    }

    fun handleAction(action: String) {
        val now = System.currentTimeMillis()
        val expiry = cooldowns[action] ?: 0L

        if (now < expiry) return

        cooldowns[action] = now + COOLDOWN_MS

        val actionId = when (action) {
            ACTION_CALL_WAITER -> "call_waiter"
            ACTION_CONTROLLER -> "controller"
            ACTION_ORDER_DRINK_1 -> "order_drink_1"
            ACTION_ORDER_DRINK_2 -> "order_drink_2"
            else -> return
        }

        // Forward to Flutter — Dart handles all actions (service requests via Dio, drinks via order API)
        MainActivity.sessionChannel?.invokeMethod("onAction", actionId)

        refresh()
        scheduleCooldownUpdates()
    }

    private fun scheduleCooldownUpdates() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                val now = System.currentTimeMillis()
                val hasActiveCooldown = cooldowns.any { now < it.value }
                if (hasActiveCooldown) {
                    refresh()
                    handler.postDelayed(this, 1000)
                } else {
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
    companion object {
        fun sendDirectRequest(context: Context, action: String) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val sessionId = prefs.getLong("flutter.active_session_id", -1)
            val roomId = prefs.getLong("flutter.active_session_room_id", -1)
            val accessToken = prefs.getString("flutter.active_session_access_token", null)
            val branchId = prefs.getLong("flutter.active_session_branch_id", -1)
            val roomNameEn = prefs.getString("flutter.active_session_room_name_en", "") ?: ""
            val roomNameAr = prefs.getString("flutter.active_session_room_name_ar", null)

            if (sessionId == -1L || roomId == -1L || accessToken == null) return

            val requestType = when (action) {
                SessionNotificationHelper.ACTION_CALL_WAITER -> 1
                SessionNotificationHelper.ACTION_CONTROLLER -> 2
                else -> return
            }

            Thread {
                try {
                    val url = java.net.URL("${getBaseUrl(context)}service-requests?api-version=1.0")
                    val conn = url.openConnection() as java.net.HttpURLConnection
                    conn.requestMethod = "POST"
                    conn.setRequestProperty("Content-Type", "application/json")
                    conn.setRequestProperty("Authorization", "Bearer $accessToken")
                    if (branchId != -1L) {
                        conn.setRequestProperty("X-Branch-Id", branchId.toString())
                    }
                    conn.doOutput = true

                    val roomNameJson = if (roomNameAr != null) {
                        """{"en":"$roomNameEn","ar":"$roomNameAr"}"""
                    } else {
                        """{"en":"$roomNameEn"}"""
                    }

                    val body = """{"sessionId":$sessionId,"roomId":$roomId,"roomName":$roomNameJson,"requestType":$requestType}"""
                    conn.outputStream.bufferedWriter().use { it.write(body) }
                    conn.responseCode
                    conn.disconnect()
                } catch (_: Exception) {
                }
            }.start()
        }

        private fun getBaseUrl(context: Context): String {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            return prefs.getString("flutter.notifications_api_url", null)
                ?: "https://chillax.site/notifications-api/"
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        val helper = SessionNotificationHelper.instance
        if (helper != null) {
            helper.handleAction(action)
            return
        }

        // Fallback when Flutter engine is dead (only waiter/controller)
        if (action == SessionNotificationHelper.ACTION_CALL_WAITER ||
            action == SessionNotificationHelper.ACTION_CONTROLLER) {
            sendDirectRequest(context, action)
        }
    }
}
