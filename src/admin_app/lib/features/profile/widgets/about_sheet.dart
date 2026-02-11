import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet for About information
class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

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
                      l10n.about,
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

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 180,
                    color: colors.foreground,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    l10n.cafeAndGaming,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.mutedForeground,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    l10n.aboutDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppText(
                      l10n.version(AppConfig.appVersion),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}
