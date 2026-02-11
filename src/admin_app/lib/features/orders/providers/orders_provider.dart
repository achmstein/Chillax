import 'package:flutter/foundation.dart';
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

/// Order history state for paginated all-orders view
class OrderHistoryState {
  final bool isLoading;
  final String? error;
  final List<Order> orders;
  final bool hasMore;
  final int currentPage;

  const OrderHistoryState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
    this.hasMore = true,
    this.currentPage = 0,
  });

  OrderHistoryState copyWith({
    bool? isLoading,
    String? error,
    List<Order>? orders,
    bool? hasMore,
    int? currentPage,
  }) {
    return OrderHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
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
      // Use /pending endpoint to get all pending orders for admin management
      final response = await _api.get('pending');
      // Backend returns a list of pending orders
      final itemsList = response.data as List<dynamic>;
      final orders = itemsList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      orders.sort((a, b) => b.date.compareTo(a.date));

      state = state.copyWith(
        isLoading: false,
        orders: orders,
        pendingOrders: orders, // All returned orders are pending
      );
    } catch (e) {
      debugPrint('Failed to load orders: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> confirmOrder(int orderId) async {
    try {
      await _api.put('confirm', data: {'orderNumber': orderId});
      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Failed to confirm order: $e');
      return false;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      await _api.put('cancel', data: {'orderNumber': orderId});
      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Failed to cancel order: $e');
      return false;
    }
  }

  Future<List<Order>> getOrdersByUserId(String userId) async {
    try {
      final response = await _api.get('user/$userId');
      final data = response.data as Map<String, dynamic>;
      final itemsList = data['items'] as List<dynamic>;
      return itemsList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load user orders: $e');
      return [];
    }
  }
}

/// Orders provider
final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);

/// Provider for fetching single order details
final orderDetailsProvider = FutureProvider.family<Order, int>((ref, orderId) async {
  final api = ref.read(ordersApiProvider);
  final response = await api.get('$orderId');
  return Order.fromJson(response.data as Map<String, dynamic>);
});

/// Order history notifier for paginated all-orders
class OrderHistoryNotifier extends Notifier<OrderHistoryState> {
  late final ApiClient _api;
  static const _pageSize = 20;

  @override
  OrderHistoryState build() {
    _api = ref.read(ordersApiProvider);
    return const OrderHistoryState();
  }

  Future<void> loadOrderHistory({bool loadMore = false}) async {
    if (state.isLoading) return;

    final page = loadMore ? state.currentPage + 1 : 0;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.get('all', queryParameters: {
        'pageIndex': page,
        'pageSize': _pageSize,
      });
      final data = response.data as Map<String, dynamic>;
      final itemsList = data['items'] as List<dynamic>;
      final newOrders = itemsList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      final hasNext = data['hasNextPage'] as bool? ?? false;

      state = state.copyWith(
        isLoading: false,
        orders: loadMore ? [...state.orders, ...newOrders] : newOrders,
        hasMore: hasNext,
        currentPage: page,
      );
    } catch (e) {
      debugPrint('Failed to load order history: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Order history provider
final orderHistoryProvider =
    NotifierProvider<OrderHistoryNotifier, OrderHistoryState>(OrderHistoryNotifier.new);
