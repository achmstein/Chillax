import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user.dart';
import '../services/users_service.dart';

/// Users state
class UsersState {
  final bool isLoading;
  final String? error;
  final List<AdminUser> users;
  final int totalCount;
  final String? searchQuery;

  const UsersState({
    this.isLoading = false,
    this.error,
    this.users = const [],
    this.totalCount = 0,
    this.searchQuery,
  });

  UsersState copyWith({
    bool? isLoading,
    String? error,
    List<AdminUser>? users,
    int? totalCount,
    String? searchQuery,
    bool clearSearch = false,
    bool clearError = false,
  }) {
    return UsersState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      users: users ?? this.users,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Users provider
class UsersNotifier extends Notifier<UsersState> {
  late UsersRepository _repository;

  @override
  UsersState build() {
    _repository = ref.read(usersRepositoryProvider);
    return const UsersState();
  }

  Future<void> loadUsers({int first = 0, int max = 50}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final users = await _repository.getUsers(
        first: first,
        max: max,
        role: 'Admin',
        search: state.searchQuery,
      );

      state = state.copyWith(
        isLoading: false,
        users: users,
        totalCount: users.length,
      );
    } catch (e) {
      debugPrint('Failed to load users: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String? query) {
    if (query == null || query.isEmpty) {
      state = state.copyWith(clearSearch: true);
    } else {
      state = state.copyWith(searchQuery: query);
    }
    loadUsers();
  }

  Future<bool> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _repository.createAdmin(
        name: name,
        email: email,
        password: password,
      );

      // Refresh user list
      await loadUsers();
      return true;
    } catch (e) {
      debugPrint('Failed to create admin: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Users provider
final usersProvider =
    NotifierProvider<UsersNotifier, UsersState>(UsersNotifier.new);
