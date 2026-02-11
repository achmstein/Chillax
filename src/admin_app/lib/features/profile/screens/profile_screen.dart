import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/about_sheet.dart';

/// Admin profile screen - restructured with account, appearance, and about sections
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final themeState = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
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

                // Group 1: Account - Update Name, Change Password
                FTileGroup(
                  children: [
                    FTile(
                      prefix: const Icon(FIcons.user),
                      title: AppText(l10n.updateName),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => context.push('/profile/update-name'),
                    ),
                    FTile(
                      prefix: const Icon(FIcons.key),
                      title: AppText(l10n.changePassword),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => context.push('/profile/change-password'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Group 2: Appearance & Info - Theme, Language, About
                FTileGroup(
                  children: [
                    FTile(
                      prefix: const Icon(FIcons.palette),
                      title: AppText(l10n.theme),
                      subtitle: AppText(_getThemeModeName(themeState.themeMode, l10n)),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => _showThemeSelector(context, ref),
                    ),
                    FTile(
                      prefix: const Icon(FIcons.globe),
                      title: AppText(l10n.language),
                      subtitle: AppText(locale.languageCode == 'ar' ? l10n.arabic : l10n.english),
                      suffix: const Icon(FIcons.chevronRight),
                      onPress: () => _showLanguageSelector(context, ref),
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

  String _getThemeModeName(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.light;
      case AppThemeMode.dark:
        return l10n.dark;
      case AppThemeMode.system:
        return l10n.systemDefault;
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentMode = ref.read(themeProvider).themeMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) => _ThemeSelectorSheet(
        currentMode: currentMode,
        l10n: l10n,
        onThemeSelected: (mode) {
          ref.read(themeProvider.notifier).setThemeMode(mode);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) => _LanguageSelectorSheet(
        currentLocale: currentLocale,
        l10n: l10n,
        onLanguageSelected: (locale) {
          ref.read(localeProvider.notifier).setLocale(locale);
          Navigator.pop(sheetContext);
        },
      ),
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

/// Bottom sheet for selecting theme
class _ThemeSelectorSheet extends StatelessWidget {
  final AppThemeMode currentMode;
  final AppLocalizations l10n;
  final Function(AppThemeMode) onThemeSelected;

  const _ThemeSelectorSheet({
    required this.currentMode,
    required this.l10n,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      l10n.selectTheme,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(FIcons.x, size: 24, color: colors.mutedForeground),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.border),

            // Theme options
            ...AppThemeMode.values.map((mode) {
              final isSelected = currentMode == mode;
              return GestureDetector(
                onTap: () => onThemeSelected(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.15) : colors.muted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          mode == AppThemeMode.light
                              ? FIcons.sun
                              : mode == AppThemeMode.dark
                                  ? FIcons.moon
                                  : FIcons.monitor,
                          size: 22,
                          color: isSelected ? colors.primary : colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              _getThemeModeName(mode),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              _getThemeModeDescription(mode),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(FIcons.check, size: 14, color: colors.primaryForeground),
                        ),
                    ],
                  ),
                ),
              );
            }),

            SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.light;
      case AppThemeMode.dark:
        return l10n.dark;
      case AppThemeMode.system:
        return l10n.systemDefault;
    }
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.lightThemeDescription;
      case AppThemeMode.dark:
        return l10n.darkThemeDescription;
      case AppThemeMode.system:
        return l10n.systemDefaultDescription;
    }
  }
}

/// Bottom sheet for selecting language
class _LanguageSelectorSheet extends StatelessWidget {
  final Locale currentLocale;
  final AppLocalizations l10n;
  final Function(Locale) onLanguageSelected;

  const _LanguageSelectorSheet({
    required this.currentLocale,
    required this.l10n,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    final languages = [
      (locale: const Locale('en'), name: 'English', nativeName: 'English'),
      (locale: const Locale('ar'), name: '\u0627\u0644\u0639\u0631\u0628\u064A\u0629', nativeName: 'Arabic'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      l10n.selectLanguage,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(FIcons.x, size: 24, color: colors.mutedForeground),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.border),

            // Language options
            ...languages.map((lang) {
              final isSelected = currentLocale.languageCode == lang.locale.languageCode;
              return GestureDetector(
                onTap: () => onLanguageSelected(lang.locale),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.15) : colors.muted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: AppText(
                            lang.locale.languageCode.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? colors.primary : colors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppText(
                          lang.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(FIcons.check, size: 14, color: colors.primaryForeground),
                        ),
                    ],
                  ),
                ),
              );
            }),

            SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}
