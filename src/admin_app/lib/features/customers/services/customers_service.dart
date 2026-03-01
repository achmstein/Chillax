import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/customer.dart';

/// Abstract repository defining customer operations
abstract class CustomersRepository {
  Future<List<Customer>> getCustomers({
    int first = 0,
    int max = 50,
    String? search,
    String? excludeRole,
  });
  Future<Customer?> getCustomer(String customerId);
  Future<void> updateCustomerName(String customerId, String newName);
  Future<void> resetCustomerPassword(String customerId, String newPassword);
  Future<bool> toggleCustomerEnabled(String customerId);
}

/// Concrete implementation that calls the Identity API
class ApiCustomersRepository implements CustomersRepository {
  final ApiClient _api;

  ApiCustomersRepository(this._api);

  @override
  Future<List<Customer>> getCustomers({
    int first = 0,
    int max = 50,
    String? search,
    String? excludeRole,
  }) async {
    final queryParams = <String, dynamic>{
      'first': first,
      'max': max,
    };

    if (excludeRole != null) {
      queryParams['excludeRole'] = excludeRole;
    }

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _api.get('/users', queryParameters: queryParams);
    final customersData = response.data as List<dynamic>;
    return customersData
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Customer?> getCustomer(String customerId) async {
    final response = await _api.get('/users/$customerId');
    return Customer.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateCustomerName(String customerId, String newName) async {
    await _api.put('/users/$customerId/name', data: {'newName': newName});
  }

  @override
  Future<void> resetCustomerPassword(
      String customerId, String newPassword) async {
    await _api.put('/users/$customerId/password',
        data: {'newPassword': newPassword});
  }

  @override
  Future<bool> toggleCustomerEnabled(String customerId) async {
    final response = await _api.put('/users/$customerId/toggle-enabled');
    return response.data['enabled'] as bool;
  }
}

/// Provider for the customers repository
final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => ApiCustomersRepository(ref.read(identityApiProvider)),
);
