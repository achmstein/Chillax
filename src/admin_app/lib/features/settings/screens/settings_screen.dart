import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final locale = ref.watch(localeProvider);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: AppText(l10n.settings, style: const TextStyle(fontSize: 18)),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section
                AppText(
                  l10n.profile,
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
                          fallback: AppText(
                            (authState.name ?? 'A').substring(0, 1).toUpperCase(),
                          ),
                          size: 64,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                authState.name ?? l10n.adminUser,
                                style: theme.typography.lg.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AppText(
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
                                          child: AppText(role),
                                        )
                                      : FBadge(style: FBadgeStyle.secondary(),
                                          child: AppText(role),
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

                // Language section
                AppText(
                  l10n.language,
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FCard(
                  child: Column(
                    children: [
                      _LanguageItem(
                        title: l10n.english,
                        subtitle: 'English',
                        isSelected: locale.languageCode == 'en',
                        onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('en')),
                      ),
                      const FDivider(),
                      _LanguageItem(
                        title: l10n.arabic,
                        subtitle: 'العربية',
                        isSelected: locale.languageCode == 'ar',
                        onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('ar')),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // App info section
                AppText(
                  l10n.about,
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
                        title: l10n.appVersion,
                        subtitle: AppConfig.appVersion,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.dns,
                        title: l10n.identityProvider,
                        subtitle: AppConfig.keycloakUrl,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.public,
                        title: l10n.ordersApi,
                        subtitle: AppConfig.ordersApiUrl,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.videogame_asset,
                        title: l10n.roomsApi,
                        subtitle: AppConfig.roomsApiUrl,
                      ),
                      const FDivider(),
                      _SettingsItem(
                        icon: Icons.restaurant,
                        title: l10n.catalogApi,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout),
                        const SizedBox(width: 8),
                        AppText(l10n.signOut),
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
    final l10n = AppLocalizations.of(context)!;
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
            child: AppText(l10n.signOut),
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

class _LanguageItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.language,
              size: 20,
              color: isSelected ? theme.colors.primary : theme.colors.mutedForeground,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? theme.colors.primary : null,
                    ),
                  ),
                  AppText(
                    subtitle,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: theme.colors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                AppText(
                  title,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppText(
                  subtitle,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return content;
  }
}
