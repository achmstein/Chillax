import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/customer.dart';

/// Customers state
class CustomersState {
  final bool isLoading;
  final String? error;
  final List<Customer> customers;
  final int totalCount;
  final String? searchQuery;

  const CustomersState({
    this.isLoading = false,
    this.error,
    this.customers = const [],
    this.totalCount = 0,
    this.searchQuery,
  });

  CustomersState copyWith({
    bool? isLoading,
    String? error,
    List<Customer>? customers,
    int? totalCount,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return CustomersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      customers: customers ?? this.customers,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Customers provider
class CustomersNotifier extends Notifier<CustomersState> {
  late final ApiClient _api;

  @override
  CustomersState build() {
    _api = ref.read(identityApiProvider);
    return const CustomersState();
  }

  Future<void> loadCustomers({int first = 0, int max = 50}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = <String, dynamic>{
        'first': first,
        'max': max,
        'excludeRole': 'Admin', // Exclude admin users, show only customers
      };

      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        queryParams['search'] = state.searchQuery;
      }

      final response = await _api.get('/users', queryParameters: queryParams);
      final customersData = response.data as List<dynamic>;

      final customers = customersData
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        customers: customers,
        totalCount: customers.length,
      );
    } catch (e) {
      debugPrint('Failed to load customers: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String? query) {
    if (query == null || query.isEmpty) {
      state = state.copyWith(clearSearch: true);
    } else {
      state = state.copyWith(searchQuery: query);
    }
    loadCustomers();
  }

  Future<Customer?> getCustomer(String customerId) async {
    try {
      final response = await _api.get('/users/$customerId');
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}

/// Customers provider
final customersProvider =
    NotifierProvider<CustomersNotifier, CustomersState>(CustomersNotifier.new);
