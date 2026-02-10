import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
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

  String? _validatePassword(AppLocalizations l10n) {
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      return l10n.enterNewPassword;
    }
    if (password.length < 8) {
      return l10n.passwordMustBe8Chars;
    }
    if (confirm.isEmpty) {
      return l10n.pleaseConfirmPassword;
    }
    if (password != confirm) {
      return l10n.passwordsDontMatch;
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final validationError = _validatePassword(l10n);
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
            title: AppText(l10n.passwordChangedSuccessfully),
            icon: Icon(FIcons.circleCheck, color: Colors.green.shade600),
          );
        } else {
          setState(() {
            _error = l10n.failedToChangePassword;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = l10n.anErrorOccurred(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = AppLocalizations.of(context)!;

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
                  Expanded(
                    child: AppText(
                      l10n.changePassword,
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
                        title: AppText(l10n.error),
                        subtitle: AppText(_error!),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Instructions
                    AppText(
                        l10n.createStrongPassword,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        l10n.passwordRequirements,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // New password field
                      FTextField.password(
                        control: FTextFieldControl.managed(controller: _newPasswordController),
                        label: AppText(l10n.newPassword),
                        hint: l10n.enterNewPassword,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Confirm password field
                      FTextField.password(
                        control: FTextFieldControl.managed(controller: _confirmPasswordController),
                        label: AppText(l10n.confirmPassword),
                        hint: l10n.pleaseConfirmPassword,
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
                            : AppText(l10n.changePassword),
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
