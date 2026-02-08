import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/help_support_sheet.dart';
import '../widgets/about_sheet.dart';

/// Admin profile screen - redesigned with FTileGroup pattern
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
                FAvatar.raw(
                  size: 80,
                  child: AppText(
                    _getInitials(authState.name),
                    style: const TextStyle(fontSize: 32),
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

                // Email
                if (authState.email != null) ...[
                  const SizedBox(height: 4),
                  AppText(
                    authState.email!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Menu Group 1: Settings, Password, Users
                FTileGroup(
                  children: [
                    FTile(
                      prefix: const Icon(FIcons.settings),
                      title: AppText(l10n.settings),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => context.go('/settings'),
                    ),
                    FTile(
                      prefix: const Icon(FIcons.key),
                      title: AppText(l10n.changePassword),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => _showChangePasswordSheet(context),
                    ),
                    FTile(
                      prefix: const Icon(FIcons.users),
                      title: AppText(l10n.usersManagement),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => context.go('/users'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Menu Group 2: Help & Support, About
                FTileGroup(
                  children: [
                    FTile(
                      prefix: const Icon(FIcons.lifeBuoy),
                      title: AppText(l10n.helpAndSupport),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => _showHelpSheet(context),
                    ),
                    FTile(
                      prefix: const Icon(FIcons.info),
                      title: AppText(l10n.about),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => _showAboutSheet(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    style: FButtonStyle.destructive(),
                    onPress: () => _handleLogout(context, ref, l10n),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FIcons.logOut),
                        const SizedBox(width: 8),
                        AppText(l10n.signOut),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Version footer
                AppText(
                  l10n.version(AppConfig.appVersion),
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'A';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const ChangePasswordSheet(),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const HelpSupportSheet(),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const AboutSheet(),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.signOutQuestion),
        body: AppText(l10n.signOutConfirmation),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.signOut),
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
