import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/auth/auth_service.dart';
import '../models/loyalty_info.dart';

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
class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final ApiClient _api;
  final AuthState _authState;

  LoyaltyNotifier(this._api, this._authState) : super(const LoyaltyState());

  Future<void> loadLoyaltyInfo() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get(
        '/accounts/${_authState.userId}',
        queryParameters: {'api-version': '1.0'},
      );

      final loyaltyInfo = LoyaltyInfo.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        loyaltyInfo: loyaltyInfo,
      );
    } catch (e) {
      // If 404, user doesn't have loyalty account yet - this is OK
      if (e.toString().contains('404')) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load loyalty info',
        );
      }
    }
  }

  Future<void> loadRecentTransactions() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return;
    }

    try {
      final response = await _api.get(
        '/transactions/${_authState.userId}',
        queryParameters: {'api-version': '1.0', 'max': 10},
      );

      final transactions = (response.data as List<dynamic>)
          .map((e) => PointsTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

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
}

/// Loyalty provider
final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  final api = ref.read(loyaltyApiProvider);
  final authState = ref.watch(authServiceProvider);
  return LoyaltyNotifier(api, authState);
});
