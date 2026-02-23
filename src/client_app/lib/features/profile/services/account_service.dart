import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/account_balance.dart';

/// Abstract interface for account operations
abstract class AccountRepository {
  Future<AccountBalance?> getMyAccount();
  Future<List<AccountTransaction>> getMyTransactions({int? limit});
}

/// Account repository implementation using API client
class ApiAccountRepository implements AccountRepository {
  final ApiClient _apiClient;

  ApiAccountRepository(this._apiClient);

  /// Get current user's account balance and transactions
  @override
  Future<AccountBalance?> getMyAccount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>?>('my');
      if (response.data == null) {
        return null;
      }
      return AccountBalance.fromJson(response.data!);
    } catch (e) {
      // If 404 or null, user doesn't have an account yet
      return null;
    }
  }

  /// Get current user's transaction history
  @override
  Future<List<AccountTransaction>> getMyTransactions({int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) {
        queryParams['limit'] = limit;
      }
      final response = await _apiClient.get<List<dynamic>>(
        'my/transactions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return (response.data ?? [])
          .map((e) => AccountTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Provider for account repository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final apiClient = ref.watch(accountsApiProvider);
  return ApiAccountRepository(apiClient);
});
