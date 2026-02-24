import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

class UpdateNameScreen extends ConsumerStatefulWidget {
  const UpdateNameScreen({super.key});

  @override
  ConsumerState<UpdateNameScreen> createState() => _UpdateNameScreenState();
}

class _UpdateNameScreenState extends ConsumerState<UpdateNameScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current name
    final authState = ref.read(authServiceProvider);
    if (authState.name != null) {
      _nameController.text = authState.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(AppLocalizations l10n) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return l10n.fillAllFields;
    }
    return null;
  }

  Future<void> _handleUpdateName() async {
    final l10n = AppLocalizations.of(context)!;
    final validationError = _validateName(l10n);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(settingsProvider.notifier).updateName(
        _nameController.text.trim(),
      );

      if (mounted) {
        if (success) {
          context.pop();
          showFToast(
            context: context,
            title: AppText(l10n.nameUpdatedSuccessfully),
            icon: Icon(FIcons.circleCheck, color: Colors.green.shade600),
          );
        } else {
          setState(() {
            _error = l10n.failedToUpdateName;
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
    final authState = ref.watch(authServiceProvider);
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
                      l10n.updateName,
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
                        variant: FAlertVariant.destructive,
                        icon: const Icon(FIcons.circleAlert),
                        title: AppText(l10n.error),
                        subtitle: AppText(_error!),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Current name display
                    if (authState.name != null) ...[
                      AppText(
                        l10n.name,
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
                        child: AppText(
                          authState.name!,
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Instructions
                    AppText(
                      l10n.enterNewName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    FTextField(
                      control: FTextFieldControl.managed(controller: _nameController),
                      label: AppText(l10n.newName),
                      hint: l10n.yourDisplayName,
                      enabled: !_isLoading,
                      onSubmit: (_) => _handleUpdateName(),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        onPress: _isLoading ? null : _handleUpdateName,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : AppText(l10n.updateName),
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
