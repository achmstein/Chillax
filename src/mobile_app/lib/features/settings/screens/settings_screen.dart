import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authServiceProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return FScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom header with back button
            Container(
              padding: const EdgeInsetsDirectional.only(start: 8, end: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      locale.languageCode == 'ar' ? FIcons.arrowRight : FIcons.arrowLeft,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.settings,
                      style: context.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notifications Section
                    _buildSectionHeader(l10n.notifications),
                    const SizedBox(height: 8),
                    FTileGroup(
                      children: [
                        FTile(
                          title: Text(l10n.orderStatusUpdates, style: context.textStyle()),
                          subtitle: Text(l10n.orderStatusUpdatesDescription, style: context.textStyle(color: AppTheme.textMuted, fontSize: 12)),
                          suffix: FSwitch(
                            value: settingsState.preferences.orderStatusUpdates,
                            onChange: (value) {
                              ref.read(settingsProvider.notifier).updateNotificationPreference(
                                orderStatusUpdates: value,
                              );
                            },
                          ),
                        ),
                        FTile(
                          title: Text(l10n.promotionsAndOffers, style: context.textStyle()),
                          subtitle: Text(l10n.promotionsDescription, style: context.textStyle(color: AppTheme.textMuted, fontSize: 12)),
                          suffix: FSwitch(
                            value: settingsState.preferences.promotionsAndOffers,
                            onChange: (value) {
                              ref.read(settingsProvider.notifier).updateNotificationPreference(
                                promotionsAndOffers: value,
                              );
                            },
                          ),
                        ),
                        FTile(
                          title: Text(l10n.sessionReminders, style: context.textStyle()),
                          subtitle: Text(l10n.sessionRemindersDescription, style: context.textStyle(color: AppTheme.textMuted, fontSize: 12)),
                          suffix: FSwitch(
                            value: settingsState.preferences.sessionReminders,
                            onChange: (value) {
                              ref.read(settingsProvider.notifier).updateNotificationPreference(
                                sessionReminders: value,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Appearance Section
                    _buildSectionHeader(l10n.appearance),
                    const SizedBox(height: 8),
                    FTileGroup(
                      children: [
                        FTile(
                          prefix: const Icon(FIcons.palette),
                          title: Text(l10n.theme, style: context.textStyle()),
                          subtitle: Text(_getLocalizedThemeName(themeState.themeMode, l10n), style: context.textStyle()),
                          suffix: const Icon(FIcons.chevronRight),
                          onPress: () => _showThemeSelector(context, ref),
                        ),
                        FTile(
                          prefix: const Icon(FIcons.globe),
                          title: Text(l10n.language, style: context.textStyle()),
                          subtitle: Text(locale.languageCode == 'ar' ? l10n.arabic : l10n.english, style: context.textStyle()),
                          suffix: const Icon(FIcons.chevronRight),
                          onPress: () => _showLanguageSelector(context, ref),
                        ),
                      ],
                    ),

                    if (authState.isAuthenticated) ...[
                      const SizedBox(height: 24),

                      // Account Section
                      _buildSectionHeader(l10n.account),
                      const SizedBox(height: 8),
                      FTileGroup(
                        children: [
                          FTile(
                            prefix: const Icon(FIcons.lock),
                            title: Text(l10n.changePassword, style: context.textStyle()),
                            suffix: const Icon(FIcons.chevronRight),
                            onPress: () => context.push('/settings/change-password'),
                          ),
                          FTile(
                            prefix: const Icon(FIcons.mail),
                            title: Text(l10n.updateEmail, style: context.textStyle()),
                            suffix: const Icon(FIcons.chevronRight),
                            onPress: () => context.push('/settings/update-email'),
                          ),
                          FTile(
                            prefix: Icon(FIcons.trash2, color: AppTheme.errorColor),
                            title: Text(l10n.deleteAccount, style: context.textStyle(color: AppTheme.errorColor)),
                            suffix: Icon(FIcons.chevronRight, color: AppTheme.errorColor),
                            onPress: () => _showDeleteAccountDialog(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedThemeName(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.light;
      case AppThemeMode.dark:
        return l10n.dark;
      case AppThemeMode.system:
        return l10n.systemDefault;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: context.textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) => _ThemeSelectorSheet(
        onThemeSelected: (mode) {
          ref.read(themeProvider.notifier).setThemeMode(mode);
          Navigator.pop(sheetContext);
        },
        currentMode: ref.read(themeProvider).themeMode,
        l10n: l10n,
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
        onLanguageSelected: (locale) {
          ref.read(localeProvider.notifier).setLocale(locale);
          Navigator.pop(sheetContext);
        },
        currentLocale: currentLocale,
        l10n: l10n,
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: style.call,
        animation: animation,
        title: Text(l10n.deleteAccount, style: context.textStyle(fontWeight: FontWeight.bold)),
        body: Text(l10n.deleteAccountConfirmation, style: context.textStyle()),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel, style: context.textStyle()),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () async {
              Navigator.pop(dialogContext);

              final success = await ref.read(settingsProvider.notifier).deleteAccount();

              if (success && context.mounted) {
                // Sign out after account deletion
                await ref.read(authServiceProvider.notifier).signOut();
                if (context.mounted) {
                  showFToast(
                    context: context,
                    title: Text(l10n.accountDeletedSuccessfully, style: context.textStyle()),
                    icon: Icon(FIcons.check, color: AppTheme.successColor),
                  );
                }
              } else if (context.mounted) {
                showFToast(
                  context: context,
                  title: Text(l10n.failedToDeleteAccount, style: context.textStyle()),
                  icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
                );
              }
            },
            child: Text(l10n.delete, style: context.textStyle()),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for selecting theme
class _ThemeSelectorSheet extends StatelessWidget {
  final Function(AppThemeMode) onThemeSelected;
  final AppThemeMode currentMode;
  final AppLocalizations l10n;

  const _ThemeSelectorSheet({
    required this.onThemeSelected,
    required this.currentMode,
    required this.l10n,
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
                    child: Text(
                      l10n.selectTheme,
                      style: context.textStyle(
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
                            Text(
                              _getThemeModeName(mode),
                              style: context.textStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getThemeModeDescription(mode),
                              style: context.textStyle(
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

            const SizedBox(height: 16),
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
  final Function(Locale) onLanguageSelected;
  final Locale currentLocale;
  final AppLocalizations l10n;

  const _LanguageSelectorSheet({
    required this.onLanguageSelected,
    required this.currentLocale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    final languages = [
      (locale: const Locale('ar'), name: 'العربية', nativeName: 'Arabic'),
      (locale: const Locale('en'), name: 'English', nativeName: 'English'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
                    child: Text(
                      l10n.selectLanguage,
                      style: context.textStyle(
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
                          child: Text(
                            lang.locale.languageCode.toUpperCase(),
                            style: context.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? colors.primary : colors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          lang.name,
                          style: context.textStyle(
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
