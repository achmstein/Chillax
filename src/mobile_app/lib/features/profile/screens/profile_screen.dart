import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

/// User profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User avatar and info
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authState.name ?? 'Guest User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (authState.email != null) ...[
              const SizedBox(height: 4),
              Text(
                authState.email!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Menu items
            _buildMenuItem(
              icon: Icons.receipt_long,
              title: 'Order History',
              onTap: () {
                // Already in bottom nav, could deep link to orders tab
              },
            ),
            _buildMenuItem(
              icon: Icons.videogame_asset,
              title: 'Session History',
              onTap: () {
                // Navigate to rooms tab -> my sessions
              },
            ),
            _buildMenuItem(
              icon: Icons.favorite_border,
              title: 'Favorites',
              onTap: () {
                // TODO: Implement favorites
              },
            ),
            const Divider(height: 32),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                // TODO: Implement settings
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                _showHelpDialog(context);
              },
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            const Divider(height: 32),

            // Sign out button
            if (authState.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleSignOut(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleSignIn(context, ref),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // App version
            Text(
              'Version ${AppConfig.appVersion}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleSignIn(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider.notifier).signIn();
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 20),
                SizedBox(width: 8),
                Text('support@chillax.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20),
                SizedBox(width: 8),
                Text('+1 (555) 123-4567'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_cafe, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Chillax'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cafe & Gaming'),
            SizedBox(height: 16),
            Text(
              'Order delicious food & drinks, or reserve a PlayStation room for an amazing gaming experience.',
            ),
            SizedBox(height: 16),
            Text(
              'Version ${AppConfig.appVersion}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
