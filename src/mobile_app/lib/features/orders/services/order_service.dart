import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/services/cart_service.dart';
import '../models/order.dart';

/// Order service
class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  /// Get user's orders
  Future<List<Order>> getOrders() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/orders',
    );

    return (response.data ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get order by ID
  Future<Order> getOrder(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/orders/$id',
    );

    return Order.fromJson(response.data!);
  }

  /// Create new order from cart
  Future<Order> createOrder({
    required List<CartItem> items,
    int? tableNumber,
    String? customerNote,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/orders',
      data: {
        'tableNumber': tableNumber,
        'customerNote': customerNote,
        'items': items.map((item) => item.toJson()).toList(),
      },
    );

    return Order.fromJson(response.data!);
  }

  /// Cancel order
  Future<void> cancelOrder(int id) async {
    await _apiClient.put('/api/orders/$id/cancel');
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

  CheckoutNotifier(this._orderService, this._cartNotifier)
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
        tableNumber: tableNumber,
        customerNote: customerNote,
      );

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
  return CheckoutNotifier(orderService, cartNotifier);
});
