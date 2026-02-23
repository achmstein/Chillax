import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_stats.dart';
import '../models/points_transaction.dart';

/// Abstract repository defining loyalty operations
abstract class LoyaltyRepository {
  Future<List<LoyaltyAccount>> getAccounts({int first = 0, int max = 50});
  Future<LoyaltyStats> getStats();
  Future<List<TierInfo>> getTiers();
  Future<LoyaltyAccount?> getAccountByUserId(String userId);
  Future<List<PointsTransaction>> getTransactions(String userId,
      {int max = 50});
  Future<void> createAccount(String userId);
  Future<void> earnPoints({
    required String userId,
    required int points,
    required String type,
    required String description,
    String? referenceId,
  });
  Future<void> redeemPoints({
    required String userId,
    required int points,
    required String description,
    String? referenceId,
  });
  Future<void> adjustPoints({
    required String userId,
    required int points,
    required String reason,
  });
}

/// Concrete implementation that calls the Loyalty API
class ApiLoyaltyRepository implements LoyaltyRepository {
  final ApiClient _api;

  ApiLoyaltyRepository(this._api);

  @override
  Future<List<LoyaltyAccount>> getAccounts(
      {int first = 0, int max = 50}) async {
    final response = await _api.get('/accounts', queryParameters: {
      'first': first,
      'max': max,
      'api-version': '1.0',
    });
    final accountsData = response.data as List<dynamic>;
    return accountsData
        .map((e) => LoyaltyAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LoyaltyStats> getStats() async {
    final response =
        await _api.get('/stats', queryParameters: {'api-version': '1.0'});
    return LoyaltyStats.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<TierInfo>> getTiers() async {
    final response =
        await _api.get('/tiers', queryParameters: {'api-version': '1.0'});
    final tiersData = response.data as List<dynamic>;
    return tiersData
        .map((e) => TierInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LoyaltyAccount?> getAccountByUserId(String userId) async {
    final response = await _api.get(
      '/accounts/$userId',
      queryParameters: {'api-version': '1.0'},
    );
    return LoyaltyAccount.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<PointsTransaction>> getTransactions(String userId,
      {int max = 50}) async {
    final response = await _api.get(
      '/transactions/$userId',
      queryParameters: {'api-version': '1.0', 'max': max},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PointsTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createAccount(String userId) async {
    await _api.post(
      '/accounts?api-version=1.0',
      data: {'userId': userId},
    );
  }

  @override
  Future<void> earnPoints({
    required String userId,
    required int points,
    required String type,
    required String description,
    String? referenceId,
  }) async {
    await _api.post(
      '/transactions/earn?api-version=1.0',
      data: {
        'userId': userId,
        'points': points,
        'type': type,
        'description': description,
        if (referenceId != null) 'referenceId': referenceId,
      },
    );
  }

  @override
  Future<void> redeemPoints({
    required String userId,
    required int points,
    required String description,
    String? referenceId,
  }) async {
    await _api.post(
      '/transactions/redeem?api-version=1.0',
      data: {
        'userId': userId,
        'points': points,
        'description': description,
        if (referenceId != null) 'referenceId': referenceId,
      },
    );
  }

  @override
  Future<void> adjustPoints({
    required String userId,
    required int points,
    required String reason,
  }) async {
    await _api.post(
      '/transactions/adjust?api-version=1.0',
      data: {
        'userId': userId,
        'points': points,
        'reason': reason,
      },
    );
  }
}

/// Provider for the loyalty repository
final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => ApiLoyaltyRepository(ref.read(loyaltyApiProvider)),
);
