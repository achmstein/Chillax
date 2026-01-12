import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

/// User profile screen - minimalistic design
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);

    return Column(
      children: [
        // Header
        FHeader(
          title: const Text('Profile', style: TextStyle(fontSize: 18)),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User avatar and info
                FAvatar.raw(
                  size: 80,
                  child: Text(
                    authState.name?.isNotEmpty == true
                        ? authState.name![0].toUpperCase()
                        : 'G',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  authState.name ?? 'Guest User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                if (authState.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authState.email!,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
                const SizedBox(height: 32),

                // Menu items using FTile
                FTileGroup(
                  children: [
                    FTile(
                      prefix: const Icon(FIcons.receipt),
                      title: const Text('Order History'),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () {
                        // Navigate to orders
                      },
                    ),
                    FTile(
                      prefix: const Icon(FIcons.gamepad2),
                      title: const Text('Session History'),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => context.push('/sessions'),
                    ),
                    FTile(
                      prefix: const Icon(FIcons.heart),
                      title: const Text('Favorites'),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () {
                        // TODO: Implement favorites
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                FTileGroup(
                  children: [
                    FTile(
                      prefix: const Icon(FIcons.settings),
                      title: const Text('Settings'),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () {
                        // TODO: Implement settings
                      },
                    ),
                    FTile(
                      prefix: const Icon(FIcons.lifeBuoy),
                      title: const Text('Help & Support'),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => _showHelpDialog(context),
                    ),
                    FTile(
                      prefix: const Icon(FIcons.info),
                      title: const Text('About'),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => _showAboutDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sign out / Sign in button
                SizedBox(
                  width: double.infinity,
                  child: authState.isAuthenticated
                      ? FButton(
                          style: FButtonStyle.destructive(),
                          onPress: () => _handleSignOut(context, ref),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FIcons.logOut),
                              SizedBox(width: 8),
                              Text('Sign Out'),
                            ],
                          ),
                        )
                      : FButton(
                          onPress: () => _handleSignIn(context, ref),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FIcons.logIn),
                              SizedBox(width: 8),
                              Text('Sign In'),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 32),

                // App version
                Text(
                  'Version ${AppConfig.appVersion}',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: const Text('Sign Out'),
        body: const Text('Are you sure you want to sign out?'),
        direction: Axis.horizontal,
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleSignIn(BuildContext context, WidgetRef ref) {
    context.go('/login');
  }

  void _showHelpDialog(BuildContext context) {
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: const Text('Help & Support'),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Contact us:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(FIcons.mail, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text('support@chillax.com'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(FIcons.phone, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text('+1 (555) 123-4567'),
              ],
            ),
          ],
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Row(
          children: [
            Icon(FIcons.coffee, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Chillax'),
          ],
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cafe & Gaming'),
            const SizedBox(height: 16),
            const Text(
              'Order delicious food & drinks, or reserve a PlayStation room for an amazing gaming experience.',
            ),
            const SizedBox(height: 16),
            Text(
              'Version ${AppConfig.appVersion}',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
