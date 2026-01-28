import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword() {
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      return 'Please enter a new password';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (confirm.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirm) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    final validationError = _validatePassword();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(settingsProvider.notifier).changePassword(
        _newPasswordController.text,
      );

      if (mounted) {
        if (success) {
          context.pop();
          showFToast(
            context: context,
            title: const Text('Password changed successfully'),
            icon: Icon(FIcons.circleCheck, color: Colors.green.shade600),
          );
        } else {
          setState(() {
            _error = 'Failed to change password. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return FScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(FIcons.arrowLeft, size: 22),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_error != null) ...[
                      FAlert(
                        style: FAlertStyle.destructive(),
                        icon: const Icon(FIcons.circleAlert),
                        title: const Text('Error'),
                        subtitle: Text(_error!),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Instructions
                    Text(
                        'Create a strong password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your password must be at least 8 characters long. We recommend using a mix of letters, numbers, and symbols.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // New password field
                      FTextField.password(
                        control: FTextFieldControl.managed(controller: _newPasswordController),
                        label: const Text('New Password'),
                        hint: 'Enter your new password',
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Confirm password field
                      FTextField.password(
                        control: FTextFieldControl.managed(controller: _confirmPasswordController),
                        label: const Text('Confirm Password'),
                        hint: 'Re-enter your new password',
                        enabled: !_isLoading,
                        onSubmit: (_) => _handleChangePassword(),
                      ),
                      const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        onPress: _isLoading ? null : _handleChangePassword,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
