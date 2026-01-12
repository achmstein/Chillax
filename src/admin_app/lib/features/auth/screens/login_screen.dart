import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? error;

  const LoginScreen({super.key, this.error});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.error == 'not_admin') {
      _errorMessage = 'You must have Admin role to access this application.';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(authServiceProvider.notifier).signIn(
        username,
        password,
      );

      if (!mounted) return;

      switch (result) {
        case SignInResult.success:
          context.go('/dashboard');
          break;
        case SignInResult.notAdmin:
          setState(() {
            _errorMessage = 'You must have Admin role to access this application.';
          });
          break;
        case SignInResult.failed:
          setState(() {
            _errorMessage = 'Invalid username or password. Please try again.';
          });
          break;
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

    return FScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.coffee,
                      size: 64,
                      color: theme.colors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConfig.appName,
                      style: theme.typography.xl2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Dashboard',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null) ...[
                      FAlert(
                        style: FAlertStyle.destructive(),
                        icon: const Icon(Icons.warning),
                        title: const Text('Access Denied'),
                        subtitle: Text(_errorMessage!),
                      ),
                      const SizedBox(height: 24),
                    ],

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
                      onSubmit: (_) => _signIn(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        onPress: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colors.primaryForeground,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Signing in...'),
                                ],
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Version ${AppConfig.appVersion}',
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
