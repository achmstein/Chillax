import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../models/loyalty_info.dart';

/// Loyalty card widget for profile screen - Forui themed
class LoyaltyCard extends StatelessWidget {
  final LoyaltyInfo loyaltyInfo;
  final VoidCallback? onTap;

  const LoyaltyCard({
    super.key,
    required this.loyaltyInfo,
    this.onTap,
  });

  Color get _tierColor => Color(loyaltyInfo.currentTier.colorValue);

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Icon(
                    FIcons.gift,
                    color: _tierColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.loyaltyRewards,
                    style: context.textStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colors.foreground,
                    ),
                  ),
                  const Spacer(),
                  _TierBadge(tier: loyaltyInfo.currentTier),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Points row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${numberFormat.format(loyaltyInfo.pointsBalance)} pts',
                              style: context.textStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colors.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        l10n.lifetimePoints(numberFormat.format(loyaltyInfo.lifetimePoints)),
                        style: context.textStyle(
                          fontSize: 13,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),

                  // Progress to next tier
                  if (loyaltyInfo.nextTier != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: loyaltyInfo.progressToNextTier,
                        backgroundColor: _tierColor.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.pointsToNextTier(numberFormat.format(loyaltyInfo.pointsToNextTier), '${loyaltyInfo.nextTier!.name[0].toUpperCase()}${loyaltyInfo.nextTier!.name.substring(1)}'),
                          style: context.textStyle(
                            fontSize: 13,
                            color: colors.mutedForeground,
                          ),
                        ),
                        if (onTap != null)
                          Icon(
                            FIcons.chevronRight,
                            size: 18,
                            color: colors.mutedForeground,
                          ),
                      ],
                    ),
                  ] else if (onTap != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          l10n.viewHistory,
                          style: context.textStyle(
                            fontSize: 13,
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          FIcons.chevronRight,
                          size: 18,
                          color: colors.mutedForeground,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tier badge widget with metallic gradient
class _TierBadge extends StatelessWidget {
  final LoyaltyTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final gradientColors = tier.gradientColors.map((c) => Color(c)).toList();
    // Use dark text for light tier colors (silver, gold), white for darker (bronze, platinum)
    final textColor = (tier == LoyaltyTier.bronze || tier == LoyaltyTier.platinum)
        ? Colors.white
        : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(tier.colorValue).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        tier.name.toUpperCase(),
        style: context.textStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Empty state when user has no loyalty account
class LoyaltyEmptyCard extends StatelessWidget {
  final VoidCallback? onJoin;
  final bool isLoading;

  const LoyaltyEmptyCard({
    super.key,
    this.onJoin,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            FIcons.gift,
            size: 40,
            color: colors.mutedForeground,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.joinOurLoyaltyProgram,
            style: context.textStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.earnPointsDescription,
            textAlign: TextAlign.center,
            style: context.textStyle(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
          ),
          if (onJoin != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: isLoading ? null : onJoin,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: colors.background,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.joinNow, style: context.textStyle()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state for loyalty card
class LoyaltyLoadingCard extends StatelessWidget {
  const LoyaltyLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: colors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}
