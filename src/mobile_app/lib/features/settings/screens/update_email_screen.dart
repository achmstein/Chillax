import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../providers/settings_provider.dart';

class UpdateEmailScreen extends ConsumerStatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  ConsumerState<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends ConsumerState<UpdateEmailScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      return 'Please enter an email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleUpdateEmail() async {
    final validationError = _validateEmail();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(settingsProvider.notifier).updateEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        if (success) {
          context.pop();
          showFToast(
            context: context,
            title: const Text('Email updated successfully'),
            icon: Icon(FIcons.circleCheck, color: Colors.green.shade600),
          );
        } else {
          setState(() {
            _error = 'Failed to update email. Please try again.';
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
    final authState = ref.watch(authServiceProvider);

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
                      'Update Email',
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

                    // Current email display
                    if (authState.email != null) ...[
                      Text(
                        'Current Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          authState.email!,
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Instructions
                    Text(
                        'Enter your new email address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll update your account with the new email address. Make sure you have access to this email.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email field
                      FTextField.email(
                        control: FTextFieldControl.managed(controller: _emailController),
                        label: const Text('New Email'),
                        hint: 'Enter your new email address',
                        enabled: !_isLoading,
                        onSubmit: (_) => _handleUpdateEmail(),
                      ),
                      const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        onPress: _isLoading ? null : _handleUpdateEmail,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update Email'),
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
