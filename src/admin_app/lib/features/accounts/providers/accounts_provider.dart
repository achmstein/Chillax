import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../customers/models/customer.dart';
import '../models/customer_account.dart';
import '../services/accounts_service.dart';

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
  late final AccountsRepository _repository;

  @override
  AccountsState build() {
    _repository = ref.read(accountsRepositoryProvider);
    return const AccountsState();
  }

  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final accounts = await _repository.getAccounts();

      // Sort by balance descending (highest debt first)
      accounts.sort((a, b) => b.balance.compareTo(a.balance));

      state = state.copyWith(isLoading: false, accounts: accounts);
    } catch (e) {
      // Log error but don't show in UI for better UX
      debugPrint('Failed to load accounts: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<CustomerAccount?> getAccount(String customerId) async {
    try {
      return await _repository.getAccount(customerId);
    } catch (e) {
      return null;
    }
  }

  Future<void> selectAccount(String customerId) async {
    state = state.copyWith(isLoadingTransactions: true, clearError: true);
    try {
      final details = await _repository.getAccountDetails(customerId);

      state = state.copyWith(
        selectedAccount: details.account,
        selectedAccountTransactions: details.transactions,
        isLoadingTransactions: false,
      );
    } catch (e) {
      // Silently handle 404 errors - account not found is expected
      if (e is DioException && e.response?.statusCode == 404) {
        debugPrint('Account not found: $customerId');
        state = state.copyWith(
          isLoadingTransactions: false,
          clearSelectedAccount: true,
        );
        return;
      }
      // Log other errors but don't show in UI
      debugPrint('Failed to load account details: $e');
      state = state.copyWith(isLoadingTransactions: false);
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
      final users = await _repository.searchUsers(query);

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
      await _repository.addCharge(
        customerId: customerId,
        amount: amount,
        description: description,
        customerName: customerName,
      );
      await loadAccounts();
      // Refresh selected account if it's the one we just charged
      if (state.selectedAccount?.customerId == customerId) {
        await selectAccount(customerId);
      }
      return true;
    } catch (e) {
      debugPrint('Failed to add charge: $e');
      return false;
    }
  }

  Future<bool> recordPayment({
    required String customerId,
    required double amount,
    String? description,
  }) async {
    try {
      await _repository.recordPayment(
        customerId: customerId,
        amount: amount,
        description: description,
      );
      await loadAccounts();
      // Refresh selected account if it's the one we just paid
      if (state.selectedAccount?.customerId == customerId) {
        await selectAccount(customerId);
      }
      return true;
    } catch (e) {
      debugPrint('Failed to record payment: $e');
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
      final displayName = account.displayName.toLowerCase();
      final customerId = account.customerId.toLowerCase();
      return displayName.contains(query) || customerId.contains(query);
    }).toList();
  }
}

/// Accounts provider
final accountsProvider =
    NotifierProvider<AccountsNotifier, AccountsState>(AccountsNotifier.new);
