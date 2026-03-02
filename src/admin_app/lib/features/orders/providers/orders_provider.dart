import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';

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
  late OrderRepository _repository;

  @override
  OrdersState build() {
    _repository = ref.read(orderRepositoryProvider);
    return const OrdersState();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final orders = await _repository.getPendingOrders();

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
      await _repository.confirmOrder(orderId);
      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Failed to confirm order: $e');
      return false;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      await _repository.cancelOrder(orderId);
      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Failed to cancel order: $e');
      return false;
    }
  }

  Future<List<Order>> getOrdersByUserId(String userId) async {
    try {
      return await _repository.getOrdersByUserId(userId);
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
  final repository = ref.read(orderRepositoryProvider);
  return repository.getOrderDetails(orderId);
});

/// Order history notifier for paginated all-orders
class OrderHistoryNotifier extends Notifier<OrderHistoryState> {
  late OrderRepository _repository;
  static const _pageSize = 20;

  @override
  OrderHistoryState build() {
    _repository = ref.read(orderRepositoryProvider);
    return const OrderHistoryState();
  }

  Future<void> loadOrderHistory({bool loadMore = false}) async {
    if (state.isLoading) return;

    final page = loadMore ? state.currentPage + 1 : 0;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getAllOrders(
        pageIndex: page,
        pageSize: _pageSize,
      );

      state = state.copyWith(
        isLoading: false,
        orders: loadMore ? [...state.orders, ...result.orders] : result.orders,
        hasMore: result.hasNextPage,
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
