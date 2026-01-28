import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_preferences.dart';

class SettingsService {
  final ApiClient _notificationsApiClient;
  final ApiClient _identityApiClient;

  SettingsService(this._notificationsApiClient, this._identityApiClient);

  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final response = await _notificationsApiClient.get<Map<String, dynamic>>('preferences');
      if (response.data == null) {
        return const NotificationPreferences();
      }
      return NotificationPreferences.fromJson(response.data!);
    } catch (e) {
      return const NotificationPreferences();
    }
  }

  Future<void> updateNotificationPreferences(NotificationPreferences preferences) async {
    await _notificationsApiClient.put('preferences', data: preferences.toJson());
  }

  Future<void> changePassword(String newPassword) async {
    await _identityApiClient.post('change-password', data: {
      'newPassword': newPassword,
    });
  }

  Future<void> updateEmail(String newEmail) async {
    await _identityApiClient.post('update-email', data: {
      'newEmail': newEmail,
    });
  }

  Future<void> deleteAccount() async {
    await _identityApiClient.delete('delete-account');
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final notificationsApiClient = ref.watch(notificationsApiProvider);
  final identityApiClient = ref.watch(identityApiProvider);
  return SettingsService(notificationsApiClient, identityApiClient);
});
