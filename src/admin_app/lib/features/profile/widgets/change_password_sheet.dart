import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/profile_provider.dart';

/// Bottom sheet for changing password
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n) {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8) {
      return l10n.passwordMinLength;
    }
    if (newPassword != confirmPassword) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final error = _validate(l10n);

    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    setState(() => _validationError = null);

    final success = await ref
        .read(profileProvider.notifier)
        .changePassword(_newPasswordController.text);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordChangedSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(profileProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.mutedForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        l10n.changePassword,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(FIcons.x, size: 24, color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: colors.border),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New password field
                    FTextField.password(
                      control: FTextFieldControl.managed(controller: _newPasswordController),
                      label: AppText(l10n.newPassword),
                      hint: l10n.enterNewPassword,
                    ),
                    const SizedBox(height: 16),

                    // Confirm password field
                    FTextField.password(
                      control: FTextFieldControl.managed(controller: _confirmPasswordController),
                      label: AppText(l10n.confirmPassword),
                      hint: l10n.enterNewPassword,
                    ),

                    // Validation error
                    if (_validationError != null) ...[
                      const SizedBox(height: 12),
                      AppText(
                        _validationError!,
                        style: TextStyle(
                          color: colors.destructive,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    // API error
                    if (profileState.error != null) ...[
                      const SizedBox(height: 12),
                      AppText(
                        profileState.error!,
                        style: TextStyle(
                          color: colors.destructive,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        onPress: profileState.isLoading ? null : _submit,
                        child: profileState.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.background,
                                ),
                              )
                            : AppText(l10n.changePassword),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
