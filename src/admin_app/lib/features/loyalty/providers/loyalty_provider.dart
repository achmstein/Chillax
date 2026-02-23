import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_stats.dart';
import '../models/points_transaction.dart';
import '../services/loyalty_service.dart';

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
class LoyaltyNotifier extends Notifier<LoyaltyState> {
  late final LoyaltyRepository _repository;

  @override
  LoyaltyState build() {
    _repository = ref.read(loyaltyRepositoryProvider);
    return const LoyaltyState();
  }

  Future<void> loadAccounts({int first = 0, int max = 50}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final accounts = await _repository.getAccounts(first: first, max: max);

      state = state.copyWith(
        isLoading: false,
        accounts: accounts,
      );
    } catch (e) {
      debugPrint('Failed to load loyalty accounts: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _repository.getStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Stats are optional, don't fail the whole operation
    }
  }

  Future<void> loadTiers() async {
    try {
      final tiers = await _repository.getTiers();
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
      return await _repository.getAccountByUserId(userId);
    } catch (e) {
      return null;
    }
  }

  Future<List<PointsTransaction>> getTransactions(String userId, {int max = 50}) async {
    try {
      return await _repository.getTransactions(userId, max: max);
    } catch (e) {
      return [];
    }
  }

  Future<bool> createAccount(String userId) async {
    try {
      await _repository.createAccount(userId);
      await loadAccounts();
      return true;
    } catch (e) {
      debugPrint('Failed to create loyalty account: $e');
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
      await _repository.earnPoints(
        userId: userId,
        points: points,
        type: type,
        description: description,
        referenceId: referenceId,
      );
      await loadAccounts();
      return true;
    } catch (e) {
      debugPrint('Failed to add points: $e');
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
      await _repository.redeemPoints(
        userId: userId,
        points: points,
        description: description,
        referenceId: referenceId,
      );
      await loadAccounts();
      return true;
    } catch (e) {
      debugPrint('Failed to redeem points: $e');
      return false;
    }
  }

  Future<bool> adjustPoints({
    required String userId,
    required int points,
    required String reason,
  }) async {
    try {
      await _repository.adjustPoints(
        userId: userId,
        points: points,
        reason: reason,
      );
      await loadAccounts();
      await loadStats();
      return true;
    } catch (e) {
      debugPrint('Failed to adjust points: $e');
      return false;
    }
  }
}

/// Loyalty provider
final loyaltyProvider =
    NotifierProvider<LoyaltyNotifier, LoyaltyState>(LoyaltyNotifier.new);
