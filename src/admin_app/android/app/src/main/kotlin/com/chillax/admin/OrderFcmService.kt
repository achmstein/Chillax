package com.chillax.admin

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Custom FCM service for the admin app.
 *
 * Intercepts order_reminder data-only messages and builds native notifications
 * with escalating urgency:
 *   - Reminder 1-2: High-priority notification with default sound
 *   - Reminder 3+:  Full-screen intent notification with alarm sound
 *
 * All other messages are passed to Flutter's firebase_messaging plugin.
 */
class OrderFcmService : FirebaseMessagingService() {

    companion object {
        const val URGENT_CHANNEL_ID = "urgent_order_channel"
        private const val ORDER_REMINDER_NOTIFICATION_ID_BASE = 5000

        fun createUrgentChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

                val channel = NotificationChannel(
                    URGENT_CHANNEL_ID,
                    "Urgent Order Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Loud alerts for orders pending too long"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
                    enableLights(true)
                    setShowBadge(true)
                    setSound(
                        alarmSound,
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    setBypassDnd(true)
                }

                val nm = context.getSystemService(NotificationManager::class.java)
                nm.createNotificationChannel(channel)
            }
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val type = message.data["type"]

        if (type == "order_reminder") {
            handleOrderReminder(message)
            // Still call super so Flutter gets the data in foreground
            super.onMessageReceived(message)
            return
        }

        // Let Flutter's plugin handle everything else
        super.onMessageReceived(message)
    }

    private fun handleOrderReminder(message: RemoteMessage) {
        val ctx = applicationContext
        val reminderCount = message.data["reminderCount"]?.toIntOrNull() ?: 1
        val orderId = message.data["orderId"] ?: ""
        val title = message.data["title"] ?: "Order Reminder"
        val body = message.data["body"] ?: "You have a pending order"

        val isUrgent = reminderCount >= 3

        // Create intent to open the app to orders screen
        val openIntent = Intent(ctx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/orders")
            putExtra("type", "order_reminder")
        }

        val pendingOpenIntent = PendingIntent.getActivity(
            ctx, orderId.hashCode(), openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val channelId = if (isUrgent) URGENT_CHANNEL_ID else "high_priority_channel"

        val builder = NotificationCompat.Builder(ctx, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingOpenIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (isUrgent) {
            // Full-screen intent for urgent reminders — shows over lock screen
            val fullScreenIntent = Intent(ctx, FullScreenOrderActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("orderId", orderId)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("reminderCount", reminderCount)
            }

            val fullScreenPendingIntent = PendingIntent.getActivity(
                ctx, orderId.hashCode() + 1000, fullScreenIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            builder.setFullScreenIntent(fullScreenPendingIntent, true)

            // Alarm sound for pre-O devices
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                builder.setSound(alarmSound)
                builder.setVibrate(longArrayOf(0, 500, 200, 500, 200, 500))
            }
        } else {
            // Default notification sound for early reminders
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                builder.setDefaults(NotificationCompat.DEFAULT_ALL)
            }
        }

        val orderIdInt = orderId.toIntOrNull() ?: 0
        val notificationId = ORDER_REMINDER_NOTIFICATION_ID_BASE + orderIdInt
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(notificationId, builder.build())
    }
}
