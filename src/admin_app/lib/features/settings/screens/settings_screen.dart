import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const FHeader(
          title: Text('Settings'),
        ),
        const FDivider(),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section
                Text(
                  'Profile',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        FAvatar(
                          image: const AssetImage('assets/images/avatar.png'),
                          fallback: Text(
                            (authState.name ?? 'A').substring(0, 1).toUpperCase(),
                          ),
                          size: 64,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.name ?? 'Admin User',
                                style: theme.typography.lg.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authState.email ?? '',
                                style: theme.typography.base.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: authState.roles.map((role) {
                                  return role == 'Admin'
                                      ? FBadge(
                                          child: Text(role),
                                        )
                                      : FBadge(style: FBadgeStyle.secondary(), 
                                          child: Text(role),
                                        );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App info section
                Text(
                  'About',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FCard(
                  child: Column(
                    children: [
                      _SettingsItem(
                        icon: Icons.info,
                        title: 'App Version',
                        subtitle: AppConfig.appVersion,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.dns,
                        title: 'Identity Provider',
                        subtitle: AppConfig.keycloakUrl,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.public,
                        title: 'Orders API',
                        subtitle: AppConfig.ordersApiUrl,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.videogame_asset,
                        title: 'Rooms API',
                        subtitle: AppConfig.roomsApiUrl,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.restaurant,
                        title: 'Catalog API',
                        subtitle: AppConfig.catalogApiUrl,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    style: FButtonStyle.destructive(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                    onPress: () => _signOut(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Sign Out?'),
        body: const Text('Are you sure you want to sign out?'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('Cancel'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            child: const Text('Sign Out'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right),
        ],
      ),
    );

    if (onTap != null) {
      return FTappable(
        onPress: onTap,
        child: content,
      );
    }

    return content;
  }
}
