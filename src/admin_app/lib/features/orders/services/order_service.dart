import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/order.dart';

/// Abstract repository defining order operations
abstract class OrderRepository {
  Future<List<Order>> getPendingOrders();
  Future<bool> confirmOrder(int orderId);
  Future<bool> cancelOrder(int orderId);
  Future<List<Order>> getOrdersByUserId(String userId);
  Future<Order> getOrderDetails(int orderId);
  Future<({List<Order> orders, bool hasNextPage})> getAllOrders({
    required int pageIndex,
    required int pageSize,
  });
}

/// Concrete implementation that calls the Orders API
class ApiOrderRepository implements OrderRepository {
  final ApiClient _api;

  ApiOrderRepository(this._api);

  @override
  Future<List<Order>> getPendingOrders() async {
    final response = await _api.get('pending');
    final itemsList = response.data as List<dynamic>;
    final orders = itemsList
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
    orders.sort((a, b) => b.date.compareTo(a.date));
    return orders;
  }

  @override
  Future<bool> confirmOrder(int orderId) async {
    await _api.put('confirm', data: {'orderNumber': orderId});
    return true;
  }

  @override
  Future<bool> cancelOrder(int orderId) async {
    await _api.put('cancel', data: {'orderNumber': orderId});
    return true;
  }

  @override
  Future<List<Order>> getOrdersByUserId(String userId) async {
    final response = await _api.get('user/$userId');
    final data = response.data as Map<String, dynamic>;
    final itemsList = data['items'] as List<dynamic>;
    return itemsList
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Order> getOrderDetails(int orderId) async {
    final response = await _api.get('$orderId');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<({List<Order> orders, bool hasNextPage})> getAllOrders({
    required int pageIndex,
    required int pageSize,
  }) async {
    final response = await _api.get('all', queryParameters: {
      'pageIndex': pageIndex,
      'pageSize': pageSize,
    });
    final data = response.data as Map<String, dynamic>;
    final itemsList = data['items'] as List<dynamic>;
    final orders = itemsList
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasNextPage = data['hasNextPage'] as bool? ?? false;
    return (orders: orders, hasNextPage: hasNextPage);
  }
}

/// Provider for the order repository
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => ApiOrderRepository(ref.read(ordersApiProvider)),
);
