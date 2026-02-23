import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../customers/models/customer.dart';
import '../models/customer_account.dart';

/// Abstract repository defining account operations
abstract class AccountsRepository {
  Future<List<CustomerAccount>> getAccounts();
  Future<CustomerAccount?> getAccount(String customerId);
  Future<({CustomerAccount account, List<AccountTransaction> transactions})>
      getAccountDetails(String customerId);
  Future<List<Customer>> searchUsers(String query, {int max = 20});
  Future<void> addCharge({
    required String customerId,
    required double amount,
    String? description,
    String? customerName,
  });
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? description,
  });
}

/// Concrete implementation that calls the Accounts and Identity APIs
class ApiAccountsRepository implements AccountsRepository {
  final ApiClient _accountsApi;
  final ApiClient _identityApi;

  ApiAccountsRepository(this._accountsApi, this._identityApi);

  @override
  Future<List<CustomerAccount>> getAccounts() async {
    final response = await _accountsApi.get('');
    final accountsData = response.data as List<dynamic>;
    return accountsData
        .map((e) => CustomerAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CustomerAccount?> getAccount(String customerId) async {
    final response = await _accountsApi.get(customerId);
    return CustomerAccount.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<({CustomerAccount account, List<AccountTransaction> transactions})>
      getAccountDetails(String customerId) async {
    final response = await _accountsApi.get(customerId);
    final accountData = response.data as Map<String, dynamic>;
    final account = CustomerAccount.fromJson(accountData);

    // Transactions are included in the account response
    final transactionsData =
        accountData['transactions'] as List<dynamic>? ?? [];
    final transactions = transactionsData
        .map((e) => AccountTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return (account: account, transactions: transactions);
  }

  @override
  Future<List<Customer>> searchUsers(String query, {int max = 20}) async {
    final response = await _identityApi.get('/users', queryParameters: {
      'search': query,
      'max': max,
    });
    final usersData = response.data as List<dynamic>;
    return usersData
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addCharge({
    required String customerId,
    required double amount,
    String? description,
    String? customerName,
  }) async {
    await _accountsApi.post(
      '$customerId/charge',
      data: {
        'amount': amount,
        'description': description,
        if (customerName != null) 'customerName': customerName,
      },
    );
  }

  @override
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? description,
  }) async {
    await _accountsApi.post(
      '$customerId/payment',
      data: {
        'amount': amount,
        'description': description,
      },
    );
  }
}

/// Provider for the accounts repository
final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => ApiAccountsRepository(
    ref.read(accountsApiProvider),
    ref.read(identityApiProvider),
  ),
);
