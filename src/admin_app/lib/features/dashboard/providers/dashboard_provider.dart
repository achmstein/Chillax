import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../orders/models/order.dart';
import '../../rooms/models/room.dart';

/// Dashboard statistics
class DashboardStats {
  final int pendingOrdersCount;
  final int activeSessionsCount;
  final int availableRoomsCount;
  final int totalMenuItems;
  final double todayRevenue;
  final List<Order> pendingOrders;
  final List<RoomSession> activeSessions;

  const DashboardStats({
    this.pendingOrdersCount = 0,
    this.activeSessionsCount = 0,
    this.availableRoomsCount = 0,
    this.totalMenuItems = 0,
    this.todayRevenue = 0,
    this.pendingOrders = const [],
    this.activeSessions = const [],
  });
}

/// Dashboard state
class DashboardState {
  final bool isLoading;
  final String? error;
  final DashboardStats stats;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.stats = const DashboardStats(),
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardStats? stats,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

/// Dashboard provider
class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _ordersApi;
  final ApiClient _roomsApi;
  final ApiClient _catalogApi;
  Timer? _refreshTimer;

  DashboardNotifier(this._ordersApi, this._roomsApi, this._catalogApi)
      : super(const DashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch all data concurrently
      final results = await Future.wait([
        _fetchPendingOrders(),
        _fetchActiveSessions(),
        _fetchRoomStats(),
        _fetchMenuStats(),
      ]);

      final pendingOrders = results[0] as List<Order>;
      final activeSessions = results[1] as List<RoomSession>;
      final roomStats = results[2] as Map<String, dynamic>;
      final menuStats = results[3] as Map<String, dynamic>;

      // Calculate today's revenue from confirmed orders
      final todayRevenue = await _fetchTodayRevenue();

      state = state.copyWith(
        isLoading: false,
        stats: DashboardStats(
          pendingOrdersCount: pendingOrders.length,
          activeSessionsCount: activeSessions.length,
          availableRoomsCount: roomStats['available'] as int? ?? 0,
          totalMenuItems: menuStats['total'] as int? ?? 0,
          todayRevenue: todayRevenue,
          pendingOrders: pendingOrders,
          activeSessions: activeSessions,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard: $e',
      );
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      AppConfig.dashboardRefreshInterval,
      (_) => loadDashboard(),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<List<Order>> _fetchPendingOrders() async {
    try {
      final response = await _ordersApi.get('/api/orders');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .where((o) => o.status == OrderStatus.submitted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RoomSession>> _fetchActiveSessions() async {
    try {
      final response = await _roomsApi.get('/api/sessions/active');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => RoomSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchRoomStats() async {
    try {
      final response = await _roomsApi.get('/api/rooms');
      final data = response.data as List<dynamic>;
      final rooms = data.map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
      return {
        'available': rooms.where((r) => r.status == RoomStatus.available).length,
        'total': rooms.length,
      };
    } catch (e) {
      return {'available': 0, 'total': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchMenuStats() async {
    try {
      final response = await _catalogApi.get('/api/catalog/items');
      final data = response.data as List<dynamic>;
      return {'total': data.length};
    } catch (e) {
      return {'total': 0};
    }
  }

  Future<double> _fetchTodayRevenue() async {
    try {
      final response = await _ordersApi.get('/api/orders');
      final data = response.data as List<dynamic>;
      final today = DateTime.now();
      final todayOrders = data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .where((o) =>
              o.status == OrderStatus.confirmed &&
              o.date.year == today.year &&
              o.date.month == today.month &&
              o.date.day == today.day)
          .toList();
      return todayOrders.fold<double>(0.0, (sum, o) => sum + o.total);
    } catch (e) {
      return 0;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Dashboard provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final ordersApi = ref.read(ordersApiProvider);
  final roomsApi = ref.read(roomsApiProvider);
  final catalogApi = ref.read(catalogApiProvider);
  return DashboardNotifier(ordersApi, roomsApi, catalogApi);
});
