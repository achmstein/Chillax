import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_user.dart';

/// Abstract repository for admin operations
abstract class AdminsRepository {
  Future<List<AdminUser>> getAdmins(
      {int first = 0, int max = 50, String? search, String? role});
  Future<void> createAdmin(
      {required String name, required String email, required String password, bool isOwner = false});
  Future<void> updateAdminName(String adminId, String newName);
  Future<void> resetAdminPassword(String adminId, String newPassword);
  Future<bool> toggleAdminEnabled(String adminId);
}

/// API implementation of AdminsRepository
class ApiAdminsRepository implements AdminsRepository {
  final ApiClient _api;

  ApiAdminsRepository(this._api);

  @override
  Future<List<AdminUser>> getAdmins(
      {int first = 0, int max = 50, String? search, String? role}) async {
    final queryParams = <String, dynamic>{
      'first': first,
      'max': max,
    };

    if (role != null && role.isNotEmpty) {
      queryParams['role'] = role;
    }

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _api.get('/users', queryParameters: queryParams);
    final adminsData = response.data as List<dynamic>;

    return adminsData
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createAdmin(
      {required String name,
      required String email,
      required String password,
      bool isOwner = false}) async {
    await _api.post('/register-admin', data: {
      'name': name,
      'email': email,
      'password': password,
      'isOwner': isOwner,
    });
  }

  @override
  Future<void> updateAdminName(String adminId, String newName) async {
    await _api.put('/users/$adminId/name', data: {'newName': newName});
  }

  @override
  Future<void> resetAdminPassword(String adminId, String newPassword) async {
    await _api.put('/users/$adminId/password',
        data: {'newPassword': newPassword});
  }

  @override
  Future<bool> toggleAdminEnabled(String adminId) async {
    final response = await _api.put('/users/$adminId/toggle-enabled');
    return response.data['enabled'] as bool;
  }
}

/// Provider for AdminsRepository
final adminsRepositoryProvider = Provider<AdminsRepository>(
    (ref) => ApiAdminsRepository(ref.read(identityApiProvider)));
