import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../customers/models/customer.dart';
import '../models/customer_account.dart';

/// Accounts state
class AccountsState {
  final bool isLoading;
  final String? error;
  final List<CustomerAccount> accounts;
  final String? searchQuery;
  final CustomerAccount? selectedAccount;
  final List<AccountTransaction>? selectedAccountTransactions;
  final bool isLoadingTransactions;
  // For user search when adding charge
  final List<Customer> searchResults;
  final bool isSearching;

  const AccountsState({
    this.isLoading = false,
    this.error,
    this.accounts = const [],
    this.searchQuery,
    this.selectedAccount,
    this.selectedAccountTransactions,
    this.isLoadingTransactions = false,
    this.searchResults = const [],
    this.isSearching = false,
  });

  AccountsState copyWith({
    bool? isLoading,
    String? error,
    List<CustomerAccount>? accounts,
    String? searchQuery,
    CustomerAccount? selectedAccount,
    List<AccountTransaction>? selectedAccountTransactions,
    bool? isLoadingTransactions,
    List<Customer>? searchResults,
    bool? isSearching,
    bool clearSearch = false,
    bool clearError = false,
    bool clearSelectedAccount = false,
  }) {
    return AccountsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      accounts: accounts ?? this.accounts,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      selectedAccount:
          clearSelectedAccount ? null : (selectedAccount ?? this.selectedAccount),
      selectedAccountTransactions: clearSelectedAccount
          ? null
          : (selectedAccountTransactions ?? this.selectedAccountTransactions),
      isLoadingTransactions: isLoadingTransactions ?? this.isLoadingTransactions,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Accounts provider
class AccountsNotifier extends Notifier<AccountsState> {
  late final ApiClient _accountsApi;
  late final ApiClient _identityApi;

  @override
  AccountsState build() {
    _accountsApi = ref.read(accountsApiProvider);
    _identityApi = ref.read(identityApiProvider);
    return const AccountsState();
  }

  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _accountsApi.get('');
      final accountsData = response.data as List<dynamic>;
      final accounts = accountsData
          .map((e) => CustomerAccount.fromJson(e as Map<String, dynamic>))
          .toList();

      // Sort by balance descending (highest debt first)
      accounts.sort((a, b) => b.balance.compareTo(a.balance));

      state = state.copyWith(isLoading: false, accounts: accounts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load accounts: $e',
      );
    }
  }

  Future<CustomerAccount?> getAccount(String customerId) async {
    try {
      final response = await _accountsApi.get(customerId);
      return CustomerAccount.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> selectAccount(String customerId) async {
    state = state.copyWith(isLoadingTransactions: true);
    try {
      final accountResponse = await _accountsApi.get(customerId);
      final account =
          CustomerAccount.fromJson(accountResponse.data as Map<String, dynamic>);

      final transactionsResponse =
          await _accountsApi.get('$customerId/transactions');
      final transactionsData = transactionsResponse.data as List<dynamic>;
      final transactions = transactionsData
          .map((e) => AccountTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        selectedAccount: account,
        selectedAccountTransactions: transactions,
        isLoadingTransactions: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTransactions: false,
        error: 'Failed to load account details: $e',
      );
    }
  }

  void clearSelectedAccount() {
    state = state.copyWith(clearSelectedAccount: true);
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);
    try {
      final response = await _identityApi.get('/users', queryParameters: {
        'search': query,
        'max': 20,
      });
      final usersData = response.data as List<dynamic>;
      final users = usersData
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(searchResults: users, isSearching: false);
    } catch (e) {
      state = state.copyWith(searchResults: [], isSearching: false);
    }
  }

  void clearSearchResults() {
    state = state.copyWith(searchResults: [], isSearching: false);
  }

  Future<bool> addCharge({
    required String customerId,
    required double amount,
    String? description,
    String? customerName,
  }) async {
    try {
      await _accountsApi.post(
        '$customerId/charge',
        data: {
          'amount': amount,
          'description': description,
          if (customerName != null) 'customerName': customerName,
        },
      );
      await loadAccounts();
      // Refresh selected account if it's the one we just charged
      if (state.selectedAccount?.customerId == customerId) {
        await selectAccount(customerId);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add charge: $e');
      return false;
    }
  }

  Future<bool> recordPayment({
    required String customerId,
    required double amount,
    String? description,
  }) async {
    try {
      await _accountsApi.post(
        '$customerId/payment',
        data: {
          'amount': amount,
          'description': description,
        },
      );
      await loadAccounts();
      // Refresh selected account if it's the one we just paid
      if (state.selectedAccount?.customerId == customerId) {
        await selectAccount(customerId);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to record payment: $e');
      return false;
    }
  }

  void setSearchQuery(String? query) {
    if (query == null || query.isEmpty) {
      state = state.copyWith(clearSearch: true);
    } else {
      state = state.copyWith(searchQuery: query);
    }
  }

  /// Get accounts filtered by search query
  List<CustomerAccount> get filteredAccounts {
    if (state.searchQuery == null || state.searchQuery!.isEmpty) {
      return state.accounts;
    }
    final query = state.searchQuery!.toLowerCase();
    return state.accounts.where((account) {
      return account.displayName.toLowerCase().contains(query) ||
          account.customerId.toLowerCase().contains(query);
    }).toList();
  }
}

/// Accounts provider
final accountsProvider =
    NotifierProvider<AccountsNotifier, AccountsState>(AccountsNotifier.new);
