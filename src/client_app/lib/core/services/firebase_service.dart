import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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

  /// Initialize Firebase messaging and request notification permissions.
  /// Firebase.initializeApp() and Crashlytics are configured in main().
  Future<void> initialize() async {
    try {
      _initialized = true;
      _messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        await _refreshToken();

        _messaging!.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          for (final callback in _tokenRefreshCallbacks) {
            callback(newToken);
          }
        });

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        final initialMessage = await _messaging!.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }
    } catch (_) {
      // Firebase not configured — app will work without push notifications
    }
  }

  /// Refresh the FCM token.
  /// On iOS, checks for APNs token first — without it, getToken() hangs indefinitely.
  Future<String?> _refreshToken() async {
    if (_messaging == null) return null;
    try {
      // On iOS, getToken() blocks forever if APNs token is not available.
      // Check with retries and bail out if unavailable.
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 5; i++) {
          apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) return null;
      }

      _fcmToken = await _messaging!.getToken()
          .timeout(const Duration(seconds: 10));
      return _fcmToken;
    } catch (_) {
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // TODO: show in-app notification
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // TODO: navigate to relevant screen based on message data
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
