import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

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
    // Error message will be set in build() when l10n is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.error == 'not_admin' && _errorMessage == null) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        _errorMessage = l10n.adminRoleRequired;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = l10n.enterBothFields;
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
          context.go('/orders');
          break;
        case SignInResult.notAdmin:
          setState(() {
            _errorMessage = l10n.adminRoleRequired;
          });
          break;
        case SignInResult.failed:
          setState(() {
            _errorMessage = l10n.invalidCredentials;
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colors.background,
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
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin subtitle
                  Center(
                    child: AppText(
                      l10n.adminDashboard,
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
                        title: AppText(l10n.error),
                        subtitle: AppText(_errorMessage!),
                      ),
                    ),

                  // Email field
                  FTextField.email(
                    control: FTextFieldControl.managed(controller: _usernameController),
                    label: AppText(l10n.email),
                    hint: l10n.enterEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  FTextField.password(
                    control: FTextFieldControl.managed(controller: _passwordController),
                    label: AppText(l10n.password),
                    hint: l10n.enterPassword,
                    textInputAction: TextInputAction.done,
                    onSubmit: (_) => _signIn(),
                  ),
                  const SizedBox(height: 24),

                  // Sign in button
                  FButton(
                    onPress: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colors.primaryForeground,
                            ),
                          )
                        : AppText(l10n.signIn),
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
