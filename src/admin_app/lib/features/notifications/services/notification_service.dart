import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/firebase_service.dart';

/// Service for managing admin order notifications
class NotificationService {
  final ApiClient _apiClient;
  final FirebaseService _firebaseService;

  NotificationService(this._apiClient, this._firebaseService);

  /// Register admin device for order notifications
  /// Called automatically after successful admin login
  Future<bool> registerForAdminOrderNotifications() async {
    try {
      // Request notification permission first
      final hasPermission = await _firebaseService.requestPermission();
      if (!hasPermission) {
        debugPrint('Notification permission not granted');
        return false;
      }

      // Get FCM token
      final fcmToken = await _firebaseService.getToken();
      if (fcmToken == null) {
        debugPrint('Failed to get FCM token');
        return false;
      }

      // Register with backend
      final response = await _apiClient.post(
        '/subscriptions/admin-orders',
        data: {'fcmToken': fcmToken},
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      debugPrint('Admin order notification registration: ${success ? 'success' : 'failed'}');
      return success;
    } catch (e) {
      debugPrint('Error registering for admin order notifications: $e');
      return false;
    }
  }

  /// Unregister from order notifications
  /// Called on logout
  Future<void> unregisterFromAdminOrderNotifications() async {
    try {
      await _apiClient.delete('/subscriptions/admin-orders');
      debugPrint('Unregistered from admin order notifications');
    } catch (e) {
      debugPrint('Error unregistering from admin order notifications: $e');
      // Don't throw - logout should still proceed
    }
  }

  /// Setup foreground notification handling
  void setupNotificationHandling({
    required void Function(String orderId, String buyerName) onNewOrder,
  }) {
    _firebaseService.setupForegroundMessageHandler((message) {
      _handleMessage(message, onNewOrder);
    });

    _firebaseService.setupMessageOpenedAppHandler((message) {
      _handleMessage(message, onNewOrder);
    });
  }

  void _handleMessage(
    RemoteMessage message,
    void Function(String orderId, String buyerName) onNewOrder,
  ) {
    final data = message.data;
    if (data['type'] == 'new_order') {
      final orderId = data['orderId'] ?? '';
      final buyerName = data['buyerName'] ?? 'Customer';
      onNewOrder(orderId, buyerName);
    }
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.read(notificationsApiProvider);
  final firebaseService = ref.read(firebaseServiceProvider);
  return NotificationService(apiClient, firebaseService);
});
