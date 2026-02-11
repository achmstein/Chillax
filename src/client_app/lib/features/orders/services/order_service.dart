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

  /// Get user's orders with pagination
  Future<PaginatedOrders> getOrders({int pageIndex = 0, int pageSize = 10}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '',
      queryParameters: {
        'pageIndex': pageIndex,
        'pageSize': pageSize,
      },
    );

    if (response.data == null) {
      throw Exception('Failed to load orders');
    }
    return PaginatedOrders.fromJson(response.data!);
  }

  /// Get order by ID
  Future<Order> getOrder(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$id',
    );

    if (response.data == null) {
      throw Exception('Order not found');
    }
    return Order.fromJson(response.data!);
  }

  /// Create new order from cart
  /// Returns void - the backend returns 200 OK with no body on success
  Future<void> createOrder({
    required List<CartItem> items,
    required String userId,
    required String userName,
    Map<String, dynamic>? roomName,
    String? customerNote,
    int pointsToRedeem = 0,
    double loyaltyDiscount = 0,
  }) async {
    await _apiClient.post<void>(
      '',
      data: {
        'userId': userId,
        'userName': userName,
        'roomName': roomName,
        'customerNote': customerNote,
        'pointsToRedeem': pointsToRedeem,
        'loyaltyDiscount': loyaltyDiscount,
        'items': items.map((item) => item.toJson()).toList(),
      },
      headers: {'x-requestid': _uuid.v4()},
    );
    // Success if no exception thrown - API returns 200 OK with empty body
  }

  /// Cancel order
  Future<void> cancelOrder(int id) async {
    await _apiClient.put('$id/cancel');
  }

  /// Rate an order
  Future<void> rateOrder({
    required int orderId,
    required int ratingValue,
    String? comment,
  }) async {
    await _apiClient.post<void>(
      '$orderId/rating',
      data: {
        'ratingValue': ratingValue,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      headers: {'x-requestid': _uuid.v4()},
    );
  }
}

/// Provider for order service
final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(ordersApiProvider);
  return OrderService(apiClient);
});

/// Orders list state
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

/// Orders notifier with pagination support
class OrdersNotifier extends Notifier<OrdersState> {
  static const _pageSize = 10;

  @override
  OrdersState build() {
    // Load initial data
    Future.microtask(() => loadOrders());
    return const OrdersState(isLoading: true);
  }

  /// Load orders (initial load or refresh)
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(orderServiceProvider);
      final result = await service.getOrders(pageIndex: 0, pageSize: _pageSize);

      state = state.copyWith(
        orders: result.items,
        isLoading: false,
        hasMore: result.hasNextPage,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more orders (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final service = ref.read(orderServiceProvider);
      final nextPage = state.currentPage + 1;
      final result = await service.getOrders(pageIndex: nextPage, pageSize: _pageSize);

      state = state.copyWith(
        orders: [...state.orders, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasNextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh orders
  Future<void> refresh() async {
    await loadOrders();
  }
}

/// Provider for user's orders with pagination
final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);

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
class CheckoutNotifier extends Notifier<CheckoutState> {
  late final OrderService _orderService;
  late final CartNotifier _cartNotifier;
  late final MenuService _menuService;
  late final AuthState _authState;

  @override
  CheckoutState build() {
    _orderService = ref.watch(orderServiceProvider);
    _cartNotifier = ref.watch(cartProvider.notifier);
    _menuService = ref.watch(menuServiceProvider);
    _authState = ref.watch(authServiceProvider);
    return const CheckoutState();
  }

  /// Submit order
  Future<bool> submitOrder({
    required List<CartItem> items,
    Map<String, dynamic>? roomName,
    String? customerNote,
    int pointsToRedeem = 0,
    double loyaltyDiscount = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _orderService.createOrder(
        items: items,
        userId: _authState.userId ?? '',
        userName: _authState.name ?? 'Guest',
        roomName: roomName,
        customerNote: customerNote,
        pointsToRedeem: pointsToRedeem,
        loyaltyDiscount: loyaltyDiscount,
      );

      // Save user preferences for items with customizations
      await _saveUserPreferences(items);

      // Clear cart on success
      _cartNotifier.clear();

      // Refresh orders so the new order appears when navigating to orders page
      ref.read(ordersProvider.notifier).refresh();

      state = state.copyWith(isLoading: false);
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
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);
