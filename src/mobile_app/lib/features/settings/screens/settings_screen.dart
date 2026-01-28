import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
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

    return FScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom header with back button
            Container(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(FIcons.arrowLeft, size: 22),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                    _buildSectionHeader('Notifications'),
                    const SizedBox(height: 8),
                    FTileGroup(
                      children: [
                        FTile(
                          title: const Text('Order Status Updates'),
                          subtitle: Text('Get notified when your order status changes', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                          title: const Text('Promotions & Offers'),
                          subtitle: Text('Receive special deals and discounts', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                          title: const Text('Session Reminders'),
                          subtitle: Text('Get reminded before your gaming session', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                    _buildSectionHeader('Appearance'),
                    const SizedBox(height: 8),
                    FTileGroup(
                      children: [
                        FTile(
                          prefix: const Icon(FIcons.palette),
                          title: const Text('Theme'),
                          subtitle: Text(themeState.displayName),
                          suffix: const Icon(FIcons.chevronRight),
                          onPress: () => _showThemeSelector(context, ref),
                        ),
                      ],
                    ),

                    if (authState.isAuthenticated) ...[
                      const SizedBox(height: 24),

                      // Account Section
                      _buildSectionHeader('Account'),
                      const SizedBox(height: 8),
                      FTileGroup(
                        children: [
                          FTile(
                            prefix: const Icon(FIcons.lock),
                            title: const Text('Change Password'),
                            suffix: const Icon(FIcons.chevronRight),
                            onPress: () => context.push('/settings/change-password'),
                          ),
                          FTile(
                            prefix: const Icon(FIcons.mail),
                            title: const Text('Update Email'),
                            suffix: const Icon(FIcons.chevronRight),
                            onPress: () => context.push('/settings/update-email'),
                          ),
                          FTile(
                            prefix: Icon(FIcons.trash2, color: AppTheme.errorColor),
                            title: Text('Delete Account', style: TextStyle(color: AppTheme.errorColor)),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
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
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: style.call,
        animation: animation,
        title: const Text('Delete Account'),
        body: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
                    title: const Text('Account deleted successfully'),
                    icon: Icon(FIcons.check, color: AppTheme.successColor),
                  );
                }
              } else if (context.mounted) {
                showFToast(
                  context: context,
                  title: const Text('Failed to delete account'),
                  icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
                );
              }
            },
            child: const Text('Delete'),
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

  const _ThemeSelectorSheet({
    required this.onThemeSelected,
    required this.currentMode,
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
                      'Select Theme',
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
                            Text(
                              _getThemeModeName(mode),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow your device settings';
    }
  }
}
