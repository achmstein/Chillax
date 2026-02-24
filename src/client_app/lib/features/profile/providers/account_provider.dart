import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../models/account_balance.dart';
import '../services/account_service.dart';

/// Account state for mobile app
class AccountState {
  final bool isLoading;
  final String? error;
  final AccountBalance? account;

  const AccountState({
    this.isLoading = false,
    this.error,
    this.account,
  });

  AccountState copyWith({
    bool? isLoading,
    String? error,
    AccountBalance? account,
    bool clearError = false,
    bool clearAccount = false,
  }) {
    return AccountState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      account: clearAccount ? null : account ?? this.account,
    );
  }
}

/// Account notifier for mobile app
class AccountNotifier extends Notifier<AccountState> {
  AccountRepository? _service;

  AccountRepository get _accountService {
    _service ??= ref.read(accountRepositoryProvider);
    return _service!;
  }

  AuthState get _authState => ref.read(authServiceProvider);

  @override
  AccountState build() {
    return const AccountState();
  }

  /// Load account balance
  Future<void> loadAccount() async {
    final authState = _authState;
    if (!authState.isAuthenticated || authState.userId == null) {
      state = state.copyWith(clearAccount: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final account = await _accountService.getMyAccount();
      state = state.copyWith(
        isLoading: false,
        account: account,
        clearAccount: account == null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load account',
      );
    }
  }

  /// Refresh account (silent - no loading indicator)
  Future<void> refresh() async {
    final authState = _authState;
    if (!authState.isAuthenticated || authState.userId == null) {
      state = state.copyWith(clearAccount: true);
      return;
    }

    try {
      final account = await _accountService.getMyAccount();
      state = state.copyWith(
        account: account,
        clearAccount: account == null,
      );
    } catch (e) {
      // Silently fail on refresh
    }
  }
}

/// Account provider
final accountProvider = NotifierProvider<AccountNotifier, AccountState>(AccountNotifier.new);
