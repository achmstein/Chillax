import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

/// Profile state
class ProfileState {
  final bool isLoading;
  final String? error;
  final bool? passwordChangeSuccess;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.passwordChangeSuccess,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    bool? passwordChangeSuccess,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      passwordChangeSuccess:
          clearSuccess ? null : (passwordChangeSuccess ?? this.passwordChangeSuccess),
    );
  }
}

/// Profile provider for password change and other profile operations
class ProfileNotifier extends Notifier<ProfileState> {
  late final ApiClient _api;

  @override
  ProfileState build() {
    _api = ref.read(identityApiProvider);
    return const ProfileState();
  }

  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      await _api.post('/change-password', data: {
        'newPassword': newPassword,
      });

      state = state.copyWith(
        isLoading: false,
        passwordChangeSuccess: true,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to change password: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        passwordChangeSuccess: false,
      );
      return false;
    }
  }

  void clearState() {
    state = const ProfileState();
  }
}

/// Profile provider
final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
