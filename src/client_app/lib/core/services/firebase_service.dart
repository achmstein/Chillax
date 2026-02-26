import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.notification?.title}');
}

/// Firebase messaging service for handling FCM tokens and notifications
class FirebaseService {
  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _initialized = false;

  /// Callbacks to invoke when the FCM token is refreshed (e.g. re-register subscriptions)
  final List<void Function(String newToken)> _tokenRefreshCallbacks = [];

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  /// Register a callback to be invoked when the FCM token refreshes.
  void onTokenRefresh(void Function(String newToken) callback) {
    _tokenRefreshCallbacks.add(callback);
  }

  /// Initialize Firebase and request notification permissions
  Future<void> initialize() async {
    try {
      // Firebase.initializeApp() is called in main() before Crashlytics setup
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _initialized = true;

      // Disable Crashlytics in debug mode to avoid polluting reports
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);

      _messaging = FirebaseMessaging.instance;
      debugPrint('Firebase initialized successfully');

      // Request notification permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        await _refreshToken();

        // Listen for token refresh
        _messaging!.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token refreshed: ${newToken.substring(0, 20)}...');
          _fcmToken = newToken;
          // Notify listeners so they can re-register subscriptions with the new token
          for (final callback in _tokenRefreshCallbacks) {
            callback(newToken);
          }
        });

        // Setup message handlers
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Check if the app was opened from a terminated state via notification
        final initialMessage = await _messaging!.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Firebase not configured - app will work without push notifications
    }
  }

  /// Refresh the FCM token.
  /// On iOS, checks for APNs token first — without it, getToken() hangs indefinitely.
  Future<String?> _refreshToken() async {
    if (_messaging == null) return null;
    try {
      // On iOS, getToken() blocks forever if APNs token is not available.
      // Check for it first with retries, and bail out if unavailable.
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 5; i++) {
          apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          debugPrint('APNs token not available — skipping FCM getToken()');
          return null;
        }
      }

      _fcmToken = await _messaging!.getToken()
          .timeout(const Duration(seconds: 10));
      if (_fcmToken != null) {
        debugPrint('FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
  }

  /// Handle when user taps a notification (app was in background or terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.notification?.title}');
  }

  /// Get or refresh the FCM token
  Future<String?> getToken() async {
    if (_fcmToken == null) {
      return await _refreshToken();
    }
    return _fcmToken;
  }
}

/// Provider for Firebase service
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
