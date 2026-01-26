import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/order.dart';

/// Orders state
class OrdersState {
  final bool isLoading;
  final String? error;
  final List<Order> orders;
  final List<Order> pendingOrders;

  const OrdersState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
    this.pendingOrders = const [],
  });

  OrdersState copyWith({
    bool? isLoading,
    String? error,
    List<Order>? orders,
    List<Order>? pendingOrders,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      orders: orders ?? this.orders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
    );
  }
}

/// Orders provider
class OrdersNotifier extends Notifier<OrdersState> {
  late final ApiClient _api;

  @override
  OrdersState build() {
    _api = ref.read(ordersApiProvider);
    return const OrdersState();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.get('');
      final data = response.data as List<dynamic>;
      final orders = data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final pending = orders
          .where((o) => o.status == OrderStatus.submitted)
          .toList();

      state = state.copyWith(
        isLoading: false,
        orders: orders,
        pendingOrders: pending,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load orders: $e',
      );
    }
  }

  Future<bool> confirmOrder(int orderId) async {
    try {
      await _api.put('$orderId/confirm');
      await loadOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to confirm order: $e');
      return false;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      await _api.put('$orderId/cancel');
      await loadOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel order: $e');
      return false;
    }
  }
}

/// Orders provider
final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);
