import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

/// Login screen with native username/password authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSocialLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = l10n.enterBothUsernamePassword;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider.notifier);
      final success = await authService.signIn(username, password);

      if (!success && mounted) {
        setState(() {
          _error = l10n.invalidCredentials;
        });
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

  Future<void> _handleSocialSignIn(SocialProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSocialLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider.notifier);
      final success = await authService.signInWithProvider(provider);

      if (!success && mounted) {
        setState(() {
          _error = l10n.socialSignInFailed;
        });
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
          _isSocialLoading = false;
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
                    width: 200,
                    height: 200,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 32),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FAlert(
                      style: FAlertStyle.destructive(),
                      icon: Icon(FIcons.circleAlert),
                      title: AppText(l10n.error),
                      subtitle: AppText(_error!),
                    ),
                  ),

                // Username field
                FTextField.email(
                  control: FTextFieldControl.managed(controller: _usernameController),
                  label: AppText(l10n.usernameOrEmail),
                  hint: l10n.enterUsernameOrEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password field
                FTextField.password(
                  control: FTextFieldControl.managed(controller: _passwordController),
                  label: AppText(l10n.password),
                  hint: l10n.enterPassword,
                  textInputAction: TextInputAction.done,
                  onSubmit: (_) => _handleSignIn(),
                ),
                const SizedBox(height: 24),

                // Sign in button
                FButton(
                  onPress: _isLoading || _isSocialLoading ? null : _handleSignIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : AppText(l10n.signIn),
                ),
                const SizedBox(height: 24),

                // Divider with "or"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colors.border,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppText(
                        l10n.orContinueWith,
                        style: TextStyle(
                          color: colors.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colors.border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Social login buttons
                Row(
                  children: [
                    // Google button
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.outline(),
                        onPress: _isLoading || _isSocialLoading
                            ? null
                            : () => _handleSocialSignIn(SocialProvider.google),
                        child: _isSocialLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.google.com/favicon.ico',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.g_mobiledata, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  AppText(l10n.google),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Facebook button
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.outline(),
                        onPress: _isLoading || _isSocialLoading
                            ? null
                            : () => _handleSocialSignIn(SocialProvider.facebook),
                        child: _isSocialLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.facebook.com/favicon.ico',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.facebook, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  AppText(l10n.facebook),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      l10n.dontHaveAccount,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: AppText(
                        l10n.register,
                        style: TextStyle(
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
