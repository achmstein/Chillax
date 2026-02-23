import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_user.dart';

/// Abstract repository for user operations
abstract class UsersRepository {
  Future<List<AdminUser>> getUsers(
      {int first = 0, int max = 50, String? search, String? role});
  Future<void> createAdmin(
      {required String name, required String email, required String password});
}

/// API implementation of UsersRepository
class ApiUsersRepository implements UsersRepository {
  final ApiClient _api;

  ApiUsersRepository(this._api);

  @override
  Future<List<AdminUser>> getUsers(
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
    final usersData = response.data as List<dynamic>;

    return usersData
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createAdmin(
      {required String name,
      required String email,
      required String password}) async {
    await _api.post('/register-admin', data: {
      'name': name,
      'email': email,
      'password': password,
    });
  }
}

/// Provider for UsersRepository
final usersRepositoryProvider = Provider<UsersRepository>(
    (ref) => ApiUsersRepository(ref.read(identityApiProvider)));
