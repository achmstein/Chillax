import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_service.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';
import '../../../features/orders/providers/orders_provider.dart';
import '../../../features/rooms/providers/rooms_provider.dart';
import '../../../features/service_requests/providers/service_requests_provider.dart';

const String _branchKey = 'admin_selected_branch_id';

/// Cached initial branch ID loaded before app starts
int? _initialBranchId;

/// Call this before runApp() to preload the saved branch
Future<void> initializeBranch() async {
  final prefs = await SharedPreferences.getInstance();
  _initialBranchId = prefs.getInt(_branchKey);
}

class BranchState {
  final List<Branch> branches;
  final int? selectedBranchId;
  final bool isLoading;
  final String? error;

  const BranchState({
    this.branches = const [],
    this.selectedBranchId,
    this.isLoading = false,
    this.error,
  });

  Branch? get selectedBranch {
    if (selectedBranchId == null) return null;
    try {
      return branches.firstWhere((b) => b.id == selectedBranchId);
    } catch (_) {
      return null;
    }
  }

  BranchState copyWith({
    List<Branch>? branches,
    int? selectedBranchId,
    bool? isLoading,
    String? error,
  }) {
    return BranchState(
      branches: branches ?? this.branches,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BranchNotifier extends Notifier<BranchState> {
  @override
  BranchState build() {
    return BranchState(
      selectedBranchId: _initialBranchId,
      isLoading: true,
    );
  }

  /// Load branches assigned to the current admin user
  Future<void> loadBranches() async {
    try {
      final authState = ref.read(authServiceProvider);
      final userId = authState.userId;
      if (userId == null) return;

      final repo = ref.read(branchRepositoryProvider);
      final branches = await repo.getAdminBranches(userId);

      var selectedId = state.selectedBranchId;

      // If no branch selected, or selected not in assigned list, pick first
      if (selectedId == null || !branches.any((b) => b.id == selectedId)) {
        selectedId = branches.isNotEmpty ? branches.first.id : null;
        if (selectedId != null) {
          _saveBranchId(selectedId);
        }
      }

      state = state.copyWith(
        branches: branches,
        selectedBranchId: selectedId,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Failed to load admin branches: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectBranch(int branchId) async {
    if (branchId == state.selectedBranchId) return;

    state = state.copyWith(selectedBranchId: branchId);
    await _saveBranchId(branchId);

    // Invalidate branch-scoped data
    ref.read(ordersProvider.notifier).loadOrders();
    ref.invalidate(roomsProvider);
    ref.read(serviceRequestsProvider.notifier).loadRequests();

    // Re-register notifications for the new branch
    ref.read(authServiceProvider.notifier).reregisterNotifications();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await loadBranches();
  }

  Future<void> _saveBranchId(int branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_branchKey, branchId);
  }
}

final branchProvider = NotifierProvider<BranchNotifier, BranchState>(
  BranchNotifier.new,
);

/// Convenience provider for the selected branch ID
final selectedBranchIdProvider = Provider<int?>((ref) {
  return ref.watch(branchProvider).selectedBranchId;
});
