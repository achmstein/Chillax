import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/providers/loyalty_provider.dart';
import '../models/cart_item.dart';

/// Cart state notifier
class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => Cart();

  /// Add item to cart
  void addItem(CartItem item) {
    state = state.addItem(item);
  }

  /// Update item quantity
  void updateQuantity(int index, int quantity) {
    state = state.updateQuantity(index, quantity);
  }

  /// Remove item from cart
  void removeItem(int index) {
    state = state.removeItem(index);
  }

  /// Clear cart
  void clear() {
    state = state.clear();
  }
}

/// Provider for cart state
final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);

/// Provider for cart item count
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

/// Provider for cart total
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).totalPrice;
});

/// Loyalty redemption state for cart checkout
class LoyaltyRedemptionState {
  final int pointsToRedeem;
  final bool usePoints;
  final double? serverDiscount;
  final bool loyaltyError;

  const LoyaltyRedemptionState({
    this.pointsToRedeem = 0,
    this.usePoints = false,
    this.serverDiscount,
    this.loyaltyError = false,
  });

  LoyaltyRedemptionState copyWith({
    int? pointsToRedeem,
    bool? usePoints,
    double? serverDiscount,
    bool? loyaltyError,
    bool clearDiscount = false,
  }) {
    return LoyaltyRedemptionState(
      pointsToRedeem: pointsToRedeem ?? this.pointsToRedeem,
      usePoints: usePoints ?? this.usePoints,
      serverDiscount: clearDiscount ? null : (serverDiscount ?? this.serverDiscount),
      loyaltyError: loyaltyError ?? this.loyaltyError,
    );
  }
}

/// Notifier for managing loyalty point redemption during checkout
class LoyaltyRedemptionNotifier extends Notifier<LoyaltyRedemptionState> {
  Timer? _debounceTimer;

  @override
  LoyaltyRedemptionState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const LoyaltyRedemptionState();
  }

  void toggleUsePoints(bool value, int maxRedeemable) {
    if (value) {
      state = state.copyWith(usePoints: true, pointsToRedeem: maxRedeemable);
    } else {
      state = state.copyWith(usePoints: false, pointsToRedeem: 0, clearDiscount: true);
    }
    _fetchServerDiscount(value ? maxRedeemable : 0);
  }

  void setPointsToRedeem(int points) {
    state = state.copyWith(pointsToRedeem: points);
    _fetchServerDiscount(points);
  }

  void _fetchServerDiscount(int points) {
    _debounceTimer?.cancel();
    if (points <= 0) {
      state = state.copyWith(clearDiscount: true);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final value = await ref.read(loyaltyProvider.notifier).getPointsValue(points);
      if (value == null) {
        state = state.copyWith(
          loyaltyError: true,
          usePoints: false,
          pointsToRedeem: 0,
          clearDiscount: true,
        );
      } else {
        state = state.copyWith(serverDiscount: value);
      }
    });
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const LoyaltyRedemptionState();
  }
}

/// Provider for loyalty redemption state
final loyaltyRedemptionProvider =
    NotifierProvider<LoyaltyRedemptionNotifier, LoyaltyRedemptionState>(
        LoyaltyRedemptionNotifier.new);
