package com.chillax.client

import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

class SessionForegroundService : Service() {
    companion object {
        fun start(context: Context, roomName: String, duration: String, startTimeMs: Long?, locale: String, playerMode: String) {
            val intent = Intent(context, SessionForegroundService::class.java).apply {
                putExtra("roomName", roomName)
                putExtra("duration", duration)
                if (startTimeMs != null) putExtra("startTimeMs", startTimeMs)
                putExtra("locale", locale)
                putExtra("playerMode", playerMode)
            }
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, SessionForegroundService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val roomName = intent.getStringExtra("roomName") ?: ""
        val duration = intent.getStringExtra("duration") ?: ""
        val startTimeMs = if (intent.hasExtra("startTimeMs")) intent.getLongExtra("startTimeMs", 0) else null
        val locale = intent.getStringExtra("locale") ?: "en"
        val playerMode = intent.getStringExtra("playerMode") ?: "Single"

        // Build notification — try helper first, fall back to a simple notification
        val notification = SessionNotificationHelper.instance?.buildNotification(
            roomName, duration, startTimeMs, locale, playerMode
        ) ?: buildFallbackNotification(roomName, duration)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceCompat.startForeground(
                this,
                SessionNotificationHelper.NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(SessionNotificationHelper.NOTIFICATION_ID, notification)
        }

        return START_NOT_STICKY
    }

    private fun buildFallbackNotification(roomName: String, duration: String): Notification {
        return NotificationCompat.Builder(this, SessionNotificationHelper.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(roomName)
            .setContentText(duration)
            .setOngoing(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}
