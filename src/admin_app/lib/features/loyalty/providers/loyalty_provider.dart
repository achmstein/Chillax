import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_stats.dart';
import '../models/points_transaction.dart';

/// Loyalty state
class LoyaltyState {
  final bool isLoading;
  final String? error;
  final List<LoyaltyAccount> accounts;
  final LoyaltyStats? stats;
  final List<TierInfo> tiers;
  final String? searchQuery;

  const LoyaltyState({
    this.isLoading = false,
    this.error,
    this.accounts = const [],
    this.stats,
    this.tiers = const [],
    this.searchQuery,
  });

  LoyaltyState copyWith({
    bool? isLoading,
    String? error,
    List<LoyaltyAccount>? accounts,
    LoyaltyStats? stats,
    List<TierInfo>? tiers,
    String? searchQuery,
    bool clearSearch = false,
    bool clearError = false,
  }) {
    return LoyaltyState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      accounts: accounts ?? this.accounts,
      stats: stats ?? this.stats,
      tiers: tiers ?? this.tiers,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Loyalty provider
class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final ApiClient _api;

  LoyaltyNotifier(this._api) : super(const LoyaltyState());

  Future<void> loadAccounts({int first = 0, int max = 50}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'first': first,
        'max': max,
        'api-version': '1.0',
      };

      final response = await _api.get('/accounts', queryParameters: queryParams);
      final accountsData = response.data as List<dynamic>;
      final accounts = accountsData
          .map((e) => LoyaltyAccount.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        accounts: accounts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load loyalty accounts: $e',
      );
    }
  }

  Future<void> loadStats() async {
    try {
      final response = await _api.get('/stats', queryParameters: {'api-version': '1.0'});
      final stats = LoyaltyStats.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Stats are optional, don't fail the whole operation
    }
  }

  Future<void> loadTiers() async {
    try {
      final response = await _api.get('/tiers', queryParameters: {'api-version': '1.0'});
      final tiersData = response.data as List<dynamic>;
      final tiers = tiersData
          .map((e) => TierInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(tiers: tiers);
    } catch (e) {
      // Tiers are optional
    }
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadAccounts(),
      loadStats(),
      loadTiers(),
    ]);
  }

  Future<LoyaltyAccount?> getAccountByUserId(String userId) async {
    try {
      final response = await _api.get(
        '/accounts/$userId',
        queryParameters: {'api-version': '1.0'},
      );
      return LoyaltyAccount.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<PointsTransaction>> getTransactions(String userId, {int max = 50}) async {
    try {
      final response = await _api.get(
        '/transactions/$userId',
        queryParameters: {'api-version': '1.0', 'max': max},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => PointsTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> createAccount(String userId) async {
    try {
      await _api.post(
        '/accounts?api-version=1.0',
        data: {'userId': userId},
      );
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create loyalty account: $e');
      return false;
    }
  }

  Future<bool> earnPoints({
    required String userId,
    required int points,
    required String type,
    required String description,
    String? referenceId,
  }) async {
    try {
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
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add points: $e');
      return false;
    }
  }

  Future<bool> redeemPoints({
    required String userId,
    required int points,
    required String description,
    String? referenceId,
  }) async {
    try {
      await _api.post(
        '/transactions/redeem?api-version=1.0',
        data: {
          'userId': userId,
          'points': points,
          'description': description,
          if (referenceId != null) 'referenceId': referenceId,
        },
      );
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to redeem points: $e');
      return false;
    }
  }

  Future<bool> adjustPoints({
    required String userId,
    required int points,
    required String reason,
  }) async {
    try {
      await _api.post(
        '/transactions/adjust?api-version=1.0',
        data: {
          'userId': userId,
          'points': points,
          'reason': reason,
        },
      );
      await loadAccounts();
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to adjust points: $e');
      return false;
    }
  }
}

/// Loyalty provider
final loyaltyProvider =
    StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  final api = ref.read(loyaltyApiProvider);
  return LoyaltyNotifier(api);
});
