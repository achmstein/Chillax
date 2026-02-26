import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp()
      .timeout(const Duration(seconds: 5));
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
  String? get initError => _initError;
  String? _initError;

  /// Register a callback to be invoked when the FCM token refreshes.
  void onTokenRefresh(void Function(String newToken) callback) {
    _tokenRefreshCallbacks.add(callback);
  }

  /// Initialize Firebase and request notification permissions
  Future<void> initialize() async {
    final crashlytics = FirebaseCrashlytics.instance;
    try {
      // Firebase.initializeApp() is called in main() before Crashlytics setup
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp()
            .timeout(const Duration(seconds: 5));
      }
      _initialized = true;

      // Disable Crashlytics in debug mode to avoid polluting reports
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      _messaging = FirebaseMessaging.instance;
      crashlytics.log('Firebase initialized');

      // Request notification permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      crashlytics.log('Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        await _refreshToken();
        crashlytics.log('FCM token: ${_fcmToken != null ? 'obtained' : 'null'}');

        // Listen for token refresh
        _messaging!.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          for (final callback in _tokenRefreshCallbacks) {
            callback(newToken);
          }
        });

        // Setup foreground message handler
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      } else {
        crashlytics.log('Notifications not authorized: ${settings.authorizationStatus}');
      }
    } catch (e, stack) {
      _initError = e.toString();
      debugPrint('Firebase initialization failed: $e');
      crashlytics.log('FCM init error: $e');
      crashlytics.recordError(e, stack, reason: 'FCM initialization failed');
    }
  }

  /// Refresh the FCM token.
  /// On iOS, waits for the APNs token first — without it, getToken() hangs indefinitely.
  Future<String?> _refreshToken() async {
    if (_messaging == null) return null;
    try {
      // On iOS, getToken() blocks until an APNs token is available.
      // If APNs registration fails (e.g. entitlement mismatch), it hangs forever.
      // So we check for the APNs token first with retries, and bail out if unavailable.
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 5; i++) {
          apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          FirebaseCrashlytics.instance.log('APNs token unavailable after retries — skipping FCM getToken()');
          debugPrint('APNs token not available — cannot get FCM token on iOS');
          return null;
        }
      }

      _fcmToken = await _messaging!.getToken()
          .timeout(const Duration(seconds: 10));
      return _fcmToken;
    } catch (e) {
      FirebaseCrashlytics.instance.log('getToken() failed: $e');
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
