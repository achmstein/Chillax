import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../models/loyalty_info.dart';
import '../services/loyalty_service.dart';

/// Loyalty state for mobile app
class LoyaltyState {
  final bool isLoading;
  final String? error;
  final LoyaltyInfo? loyaltyInfo;
  final List<PointsTransaction> recentTransactions;

  const LoyaltyState({
    this.isLoading = false,
    this.error,
    this.loyaltyInfo,
    this.recentTransactions = const [],
  });

  LoyaltyState copyWith({
    bool? isLoading,
    String? error,
    LoyaltyInfo? loyaltyInfo,
    List<PointsTransaction>? recentTransactions,
    bool clearError = false,
  }) {
    return LoyaltyState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      loyaltyInfo: loyaltyInfo ?? this.loyaltyInfo,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

/// Loyalty notifier for mobile app
class LoyaltyNotifier extends Notifier<LoyaltyState> {
  late final LoyaltyRepository _repository;

  AuthState get _authState => ref.read(authServiceProvider);

  @override
  LoyaltyState build() {
    _repository = ref.read(loyaltyRepositoryProvider);
    // Watch auth state to rebuild when it changes
    ref.watch(authServiceProvider);
    return const LoyaltyState();
  }

  Future<void> loadLoyaltyInfo() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final loyaltyInfo = await _repository.getAccount(_authState.userId!);
      state = state.copyWith(
        isLoading: false,
        loyaltyInfo: loyaltyInfo,
      );
    } catch (e) {
      // Fail silently - loyalty is optional, cart should still work
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load loyalty info',
      );
    }
  }

  Future<void> loadRecentTransactions() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return;
    }

    try {
      final transactions = await _repository.getTransactions(_authState.userId!);
      state = state.copyWith(recentTransactions: transactions);
    } catch (e) {
      // Silently fail for transactions
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      loadLoyaltyInfo(),
      loadRecentTransactions(),
    ]);
  }

  Future<bool> joinLoyaltyProgram() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.joinProgram(_authState.userId!);

      // Reload the loyalty info after joining
      await loadLoyaltyInfo();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join loyalty program',
      );
      return false;
    }
  }

  /// Local fallback conversion rate (100 points = 1 EGP)
  static const int pointsPerPound = 100;

  /// Get maximum points that can be redeemed for a given order total
  int getMaxRedeemablePoints(double orderTotal) {
    final loyaltyInfo = state.loyaltyInfo;
    if (loyaltyInfo == null) return 0;

    // Max points based on order total (can't discount more than order value)
    final maxPointsForOrder = (orderTotal * pointsPerPound).floor();

    // Return the lesser of available points or max for order
    return loyaltyInfo.pointsBalance < maxPointsForOrder
        ? loyaltyInfo.pointsBalance
        : maxPointsForOrder;
  }

  /// Get discount value from server for the given points.
  /// Returns null if the server is unreachable.
  Future<double?> getPointsValue(int points) async {
    return _repository.getPointsValue(points);
  }
}

/// Loyalty provider
final loyaltyProvider = NotifierProvider<LoyaltyNotifier, LoyaltyState>(LoyaltyNotifier.new);
