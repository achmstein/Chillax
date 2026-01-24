import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/services/cart_service.dart';
import '../../menu/models/user_preference.dart';
import '../../menu/services/menu_service.dart';
import '../models/order.dart';

const _uuid = Uuid();

/// Order service
class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  /// Get user's orders
  Future<List<Order>> getOrders() async {
    final response = await _apiClient.get<List<dynamic>>(
      '',
    );

    return (response.data ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get order by ID
  Future<Order> getOrder(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$id',
    );

    return Order.fromJson(response.data!);
  }

  /// Create new order from cart
  Future<Order> createOrder({
    required List<CartItem> items,
    required String userId,
    required String userName,
    int? tableNumber,
    String? customerNote,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '',
      data: {
        'userId': userId,
        'userName': userName,
        'tableNumber': tableNumber,
        'customerNote': customerNote,
        'items': items.map((item) => item.toJson()).toList(),
      },
      headers: {'x-requestid': _uuid.v4()},
    );

    return Order.fromJson(response.data!);
  }

  /// Cancel order
  Future<void> cancelOrder(int id) async {
    await _apiClient.put('$id/cancel');
  }
}

/// Provider for order service
final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(ordersApiProvider);
  return OrderService(apiClient);
});

/// Provider for user's orders
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final service = ref.watch(orderServiceProvider);
  return service.getOrders();
});

/// Provider for single order
final orderProvider = FutureProvider.family<Order, int>((ref, id) async {
  final service = ref.watch(orderServiceProvider);
  return service.getOrder(id);
});

/// Checkout state
class CheckoutState {
  final bool isLoading;
  final String? error;
  final Order? order;

  const CheckoutState({
    this.isLoading = false,
    this.error,
    this.order,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? error,
    Order? order,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      order: order ?? this.order,
    );
  }
}

/// Checkout notifier
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final OrderService _orderService;
  final CartNotifier _cartNotifier;
  final MenuService _menuService;
  final AuthState _authState;

  CheckoutNotifier(this._orderService, this._cartNotifier, this._menuService, this._authState)
      : super(const CheckoutState());

  /// Submit order
  Future<bool> submitOrder({
    required List<CartItem> items,
    int? tableNumber,
    String? customerNote,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = await _orderService.createOrder(
        items: items,
        userId: _authState.userId ?? '',
        userName: _authState.name ?? 'Guest',
        tableNumber: tableNumber,
        customerNote: customerNote,
      );

      // Save user preferences for items with customizations
      await _saveUserPreferences(items);

      // Clear cart on success
      _cartNotifier.clear();

      state = state.copyWith(isLoading: false, order: order);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Save user preferences for ordered items with customizations
  Future<void> _saveUserPreferences(List<CartItem> items) async {
    try {
      final preferencesToSave = items
          .where((item) => item.selectedCustomizations.isNotEmpty)
          .map((item) => SaveItemPreference(
                catalogItemId: item.productId,
                selectedOptions: item.selectedCustomizations
                    .map((c) => UserPreferenceOption(
                          customizationId: c.customizationId,
                          optionId: c.optionId,
                        ))
                    .toList(),
              ))
          .toList();

      if (preferencesToSave.isNotEmpty) {
        await _menuService.saveUserPreferences(
          SaveUserPreferencesRequest(items: preferencesToSave),
        );
      }
    } catch (e) {
      // Silently fail - preferences are not critical to order success
    }
  }

  /// Reset checkout state
  void reset() {
    state = const CheckoutState();
  }
}

/// Provider for checkout
final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final cartNotifier = ref.watch(cartProvider.notifier);
  final menuService = ref.watch(menuServiceProvider);
  final authState = ref.watch(authServiceProvider);
  return CheckoutNotifier(orderService, cartNotifier, menuService, authState);
});
