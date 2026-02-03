import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/users_provider.dart';

/// Bottom sheet for adding a new admin user
class AddAdminSheet extends ConsumerStatefulWidget {
  const AddAdminSheet({super.key});

  @override
  ConsumerState<AddAdminSheet> createState() => _AddAdminSheetState();
}

class _AddAdminSheetState extends ConsumerState<AddAdminSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _validationError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n) {
    if (_nameController.text.trim().isEmpty) {
      return l10n.nameRequired.replaceAll(' *', '');
    }
    if (_emailController.text.trim().isEmpty) {
      return l10n.email;
    }
    if (_passwordController.text.length < 8) {
      return l10n.passwordMinLength;
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

    setState(() {
      _validationError = null;
      _isLoading = true;
    });

    final success = await ref.read(usersProvider.notifier).createAdmin(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminCreatedSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;
    final usersState = ref.watch(usersProvider);

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
                        l10n.addAdmin,
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
                    // Name field
                    FTextField(
                      control: FTextFieldControl.managed(controller: _nameController),
                      label: AppText(l10n.name),
                      hint: l10n.enterName,
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    FTextField.email(
                      control: FTextFieldControl.managed(controller: _emailController),
                      label: AppText(l10n.email),
                      hint: l10n.enterEmail,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    FTextField.password(
                      control: FTextFieldControl.managed(controller: _passwordController),
                      label: AppText(l10n.password),
                      hint: l10n.enterPassword,
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
                    if (usersState.error != null) ...[
                      const SizedBox(height: 12),
                      AppText(
                        usersState.error!,
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
                        onPress: _isLoading ? null : _submit,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.background,
                                ),
                              )
                            : AppText(l10n.create),
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
