import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

/// Admin profile screen - simple and minimal
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header
        FHeader(
          title: AppText(l10n.profile, style: const TextStyle(fontSize: 18)),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // User avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: AppText(
                      (authState.name ?? 'A').substring(0, 1).toUpperCase(),
                      style: theme.typography.xl.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 32,
                        color: theme.colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                AppText(
                  authState.name ?? l10n.adminUser,
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                if (authState.email != null)
                  AppText(
                    authState.email!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),

                const SizedBox(height: 32),

                // Settings section
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.settings_outlined,
                        title: l10n.settings,
                        onTap: () => context.go('/settings'),
                      ),
                      Divider(height: 1, color: theme.colors.border),
                      _ProfileMenuItem(
                        icon: Icons.logout,
                        title: l10n.logout,
                        isDestructive: true,
                        onTap: () => _handleLogout(context, ref, l10n),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.logout),
        body: AppText(l10n.logoutConfirmation),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.logout),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authServiceProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}

/// Profile menu item widget
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = isDestructive ? theme.colors.destructive : theme.colors.foreground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  title,
                  style: theme.typography.sm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
