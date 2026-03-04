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
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authServiceProvider);
    if (authState.name != null) {
      _nameController.text = authState.name!;
    }
    // Load current phone from profile
    _loadCurrentPhone();
  }

  Future<void> _loadCurrentPhone() async {
    final phone = await ref.read(settingsProvider.notifier).getPhoneNumber();
    if (phone != null && mounted) {
      _phoneController.text = phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = l10n.fillAllFields);
      return;
    }

    // Egyptian phone validation: 01xxxxxxxxx (11 digits starting with 01)
    if (!RegExp(r'^01[0-9]{9}$').hasMatch(phone)) {
      setState(() => _error = l10n.invalidPhone);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(settingsProvider.notifier).updateProfile(
        name,
        phone,
      );

      if (mounted) {
        if (success) {
          context.pop();
          showFToast(
            context: context,
            title: AppText(l10n.profileUpdatedSuccessfully),
            icon: Icon(FIcons.circleCheck, color: Colors.green.shade600),
          );
        } else {
          setState(() {
            _error = l10n.failedToUpdateProfile;
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
                      l10n.updateProfile,
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

                    // Name field
                    FTextField(
                      control: FTextFieldControl.managed(controller: _nameController),
                      label: AppText(l10n.name),
                      hint: l10n.yourDisplayName,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    FTextField(
                      control: FTextFieldControl.managed(controller: _phoneController),
                      label: AppText(l10n.phoneNumber),
                      hint: l10n.enterPhoneNumber,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        onPress: _isLoading ? null : _handleUpdate,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : AppText(l10n.updateProfile),
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
