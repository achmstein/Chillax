import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

/// Abstract repository for profile operations
abstract class ProfileRepository {
  Future<void> changePassword(String newPassword);
  Future<void> updateName(String newName);
}

/// API implementation of ProfileRepository
class ApiProfileRepository implements ProfileRepository {
  final ApiClient _api;

  ApiProfileRepository(this._api);

  @override
  Future<void> changePassword(String newPassword) async {
    await _api.post('/change-password', data: {
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> updateName(String newName) async {
    await _api.post('update-name', data: {
      'newName': newName,
    });
  }
}

/// Provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ApiProfileRepository(ref.read(identityApiProvider)));
