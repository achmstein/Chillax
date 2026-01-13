import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
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
                  const SizedBox(height: 16),

                  // Admin subtitle
                  Center(
                    child: Text(
                      'Admin Dashboard',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FAlert(
                        style: FAlertStyle.destructive(),
                        icon: const Icon(Icons.error_outline),
                        title: const Text('Error'),
                        subtitle: Text(_errorMessage!),
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
                    onSubmit: (_) => _signIn(),
                  ),
                  const SizedBox(height: 24),

                  // Sign in button
                  FButton(
                    onPress: _isLoading ? null : _signIn,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
