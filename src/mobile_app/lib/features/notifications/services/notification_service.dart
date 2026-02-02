import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/firebase_service.dart';

/// Subscription status response from the backend
class SubscriptionStatus {
  final int? id;
  final bool isSubscribed;
  final DateTime? createdAt;

  SubscriptionStatus({
    this.id,
    required this.isSubscribed,
    this.createdAt,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      id: json['id'] as int?,
      isSubscribed: true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  factory SubscriptionStatus.notSubscribed() {
    return SubscriptionStatus(isSubscribed: false);
  }
}

/// Service for handling notification subscriptions
class NotificationService {
  final ApiClient _apiClient;
  final FirebaseService _firebaseService;

  NotificationService(this._apiClient, this._firebaseService);

  /// Subscribe to room availability notifications
  Future<bool> subscribeToRoomAvailability({String preferredLanguage = 'en'}) async {
    try {
      final fcmToken = await _firebaseService.getToken();
      if (fcmToken == null) {
        debugPrint('Cannot subscribe: FCM token not available');
        return false;
      }

      final response = await _apiClient.post(
        'subscriptions/room-availability',
        data: {
          'fcmToken': fcmToken,
          'preferredLanguage': preferredLanguage,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('Successfully subscribed to room availability notifications');
        return true;
      } else if (response.statusCode == 409) {
        // Already subscribed - that's fine
        debugPrint('Already subscribed to room availability notifications');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to subscribe to room availability: $e');
      return false;
    }
  }

  /// Unsubscribe from room availability notifications
  Future<bool> unsubscribeFromRoomAvailability() async {
    try {
      final response = await _apiClient.delete('subscriptions/room-availability');

      if (response.statusCode == 204) {
        debugPrint('Successfully unsubscribed from room availability notifications');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to unsubscribe from room availability: $e');
      return false;
    }
  }

  /// Check if user is subscribed to room availability notifications
  Future<SubscriptionStatus> getRoomAvailabilitySubscription() async {
    try {
      final response = await _apiClient.get('subscriptions/room-availability');

      if (response.statusCode == 200 && response.data != null) {
        return SubscriptionStatus.fromJson(response.data as Map<String, dynamic>);
      }
      return SubscriptionStatus.notSubscribed();
    } catch (e) {
      debugPrint('Failed to get room availability subscription: $e');
      return SubscriptionStatus.notSubscribed();
    }
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.read(notificationsApiProvider);
  final firebaseService = ref.read(firebaseServiceProvider);
  return NotificationService(apiClient, firebaseService);
});

/// State notifier for room availability subscription
class RoomAvailabilityNotifier extends Notifier<AsyncValue<bool>> {
  late final NotificationService _notificationService;

  @override
  AsyncValue<bool> build() {
    _notificationService = ref.read(notificationServiceProvider);
    _loadSubscriptionStatus();
    return const AsyncValue.loading();
  }

  Future<void> _loadSubscriptionStatus() async {
    state = const AsyncValue.loading();
    try {
      final status = await _notificationService.getRoomAvailabilitySubscription();
      state = AsyncValue.data(status.isSubscribed);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> subscribe({String preferredLanguage = 'en'}) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      final success = await _notificationService.subscribeToRoomAvailability(
        preferredLanguage: preferredLanguage,
      );
      if (success) {
        state = const AsyncValue.data(true);
      } else {
        state = previousState;
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> unsubscribe() async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      final success = await _notificationService.unsubscribeFromRoomAvailability();
      if (success) {
        state = const AsyncValue.data(false);
      } else {
        state = previousState;
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void refresh() {
    _loadSubscriptionStatus();
  }
}

/// Provider for room availability subscription state
final roomAvailabilitySubscriptionProvider =
    NotifierProvider<RoomAvailabilityNotifier, AsyncValue<bool>>(RoomAvailabilityNotifier.new);
