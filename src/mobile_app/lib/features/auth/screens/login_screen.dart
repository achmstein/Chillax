import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';

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
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter both username and password.';
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
          _error = 'Invalid username or password. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred: $e';
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
    setState(() {
      _isSocialLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider.notifier);
      final success = await authService.signInWithProvider(provider);

      if (!success && mounted) {
        setState(() {
          _error = 'Social sign in failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred: $e';
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
                      title: const Text('Error'),
                      subtitle: Text(_error!),
                    ),
                  ),

                // Username field
                FTextField.email(
                  control: FTextFieldControl.managed(controller: _usernameController),
                  label: const Text('Username or Email'),
                  hint: 'Enter your username or email',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password field
                FTextField.password(
                  control: FTextFieldControl.managed(controller: _passwordController),
                  label: const Text('Password'),
                  hint: 'Enter your password',
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
                      : const Text('Sign In'),
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
                      child: Text(
                        'or continue with',
                        style: theme.typography.sm.copyWith(
                          color: colors.mutedForeground,
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
                                  const Text('Google'),
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
                                  const Text('Facebook'),
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
                    Text(
                      "Don't have an account? ",
                      style: theme.typography.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Register',
                        style: theme.typography.sm.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
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
