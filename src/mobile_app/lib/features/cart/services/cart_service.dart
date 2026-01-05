import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';

/// Cart state notifier
class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(Cart());

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
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

/// Provider for cart item count
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

/// Provider for cart total
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).totalPrice;
});
