import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Registration screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _error = l10n.fillAllFields;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = l10n.passwordsDontMatch;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = l10n.passwordTooShort;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final authService = ref.read(authServiceProvider.notifier);
      final success = await authService.register(name, username, email, password);

      if (mounted) {
        if (success) {
          // Auto-login after successful registration
          final loginSuccess = await authService.signIn(username, password);
          if (mounted) {
            if (!loginSuccess) {
              // If auto-login fails, show message and redirect to login
              setState(() {
                _success = l10n.registrationSuccessful;
              });
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) {
                context.go('/login');
              }
            }
            // If login succeeds, router will automatically redirect to home
          }
        } else {
          setState(() {
            _error = l10n.registrationFailed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = l10n.anErrorOccurred(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
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

    return Scaffold(
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
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  l10n.createAccount,
                  style: context.textStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.foreground,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Success message
                if (_success != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FAlert(
                      style: FAlertStyle.primary(),
                      icon: Icon(FIcons.check),
                      title: Text(l10n.success),
                      subtitle: Text(_success!),
                    ),
                  ),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FAlert(
                      style: FAlertStyle.destructive(),
                      icon: Icon(FIcons.circleAlert),
                      title: Text(l10n.error),
                      subtitle: Text(_error!),
                    ),
                  ),

                // Name field
                FTextField(
                  control: FTextFieldControl.managed(controller: _nameController),
                  label: Text(l10n.name),
                  hint: l10n.yourDisplayName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Username field
                FTextField(
                  control: FTextFieldControl.managed(controller: _usernameController),
                  label: Text(l10n.username),
                  hint: l10n.chooseUsername,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email field
                FTextField.email(
                  control: FTextFieldControl.managed(controller: _emailController),
                  label: Text(l10n.email),
                  hint: l10n.enterEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password field
                FTextField.password(
                  control: FTextFieldControl.managed(controller: _passwordController),
                  label: Text(l10n.password),
                  hint: l10n.createPassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Confirm password field
                FTextField.password(
                  control: FTextFieldControl.managed(controller: _confirmPasswordController),
                  label: Text(l10n.confirmPassword),
                  hint: l10n.confirmYourPassword,
                  textInputAction: TextInputAction.done,
                  onSubmit: (_) => _handleRegister(),
                ),
                const SizedBox(height: 24),

                // Register button
                FButton(
                  onPress: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.register),
                ),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: context.textStyle(
                        color: colors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        l10n.signIn,
                        style: context.textStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
