import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

/// Screen shown after social sign-in when the user's profile is incomplete
/// (missing name or phone number).
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth state if it's not an email
    final authState = ref.read(authServiceProvider);
    final name = authState.name;
    if (name != null && !name.contains('@')) {
      _nameController.text = name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
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
      final authService = ref.read(authServiceProvider.notifier);
      final success = await authService.completeProfile(name, phone);

      if (mounted && !success) {
        setState(() => _error = l10n.profileCompletionFailed);
      }
      // On success, router redirect will send user to /menu
    } catch (e) {
      if (mounted) {
        setState(() => _error = l10n.profileCompletionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  AppText(
                    l10n.completeYourProfile,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.foreground,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  AppText(
                    l10n.completeProfileDescription,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FAlert(
                        variant: FAlertVariant.destructive,
                        icon: Icon(FIcons.circleAlert),
                        title: AppText(l10n.error),
                        subtitle: AppText(_error!),
                      ),
                    ),

                  // Name field
                  FTextField(
                    control:
                        FTextFieldControl.managed(controller: _nameController),
                    label: AppText(l10n.name),
                    hint: l10n.yourDisplayName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Phone field
                  FTextField(
                    control:
                        FTextFieldControl.managed(controller: _phoneController),
                    label: AppText(l10n.phoneNumber),
                    hint: l10n.enterPhoneNumber,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.phone,
                    onSubmit: (_) => _handleSubmit(),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  FButton(
                    onPress: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : AppText(l10n.done),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
