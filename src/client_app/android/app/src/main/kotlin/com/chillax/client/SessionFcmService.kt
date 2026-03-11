package com.chillax.client

import android.app.NotificationManager
import android.content.Context
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Handles session_ended FCM messages natively to dismiss the notification
 * immediately, even when the Flutter engine is not running.
 *
 * All other FCM messages are handled by Flutter's firebase_messaging plugin.
 */
class SessionFcmService : FirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        val type = message.data["type"]

        if (type == "session_ended") {
            // Dismiss the ongoing session notification immediately
            val helper = SessionNotificationHelper.instance
            if (helper != null) {
                helper.dismiss()
            } else {
                // Helper not alive — dismiss notification and stop service directly
                SessionForegroundService.stop(this)
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.cancel(SessionNotificationHelper.NOTIFICATION_ID)
            }
        }

        // Let Flutter's plugin handle everything else (including session_ended
        // for Dart-side state refresh)
        super.onMessageReceived(message)
    }
}
