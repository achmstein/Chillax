import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet for Help & Support
class HelpSupportSheet extends StatelessWidget {
  const HelpSupportSheet({super.key});

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
                      l10n.helpAndSupport,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    l10n.needHelpContactUs,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ContactRow(
                    icon: FIcons.mail,
                    text: l10n.supportEmail,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: FIcons.phone,
                    text: l10n.supportPhone,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: FIcons.clock,
                    text: l10n.supportHours,
                    colors: colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final dynamic colors;

  const _ContactRow({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colors.mutedForeground),
        ),
        const SizedBox(width: 12),
        AppText(
          text,
          style: TextStyle(
            fontSize: 15,
            color: colors.foreground,
          ),
        ),
      ],
    );
  }
}
