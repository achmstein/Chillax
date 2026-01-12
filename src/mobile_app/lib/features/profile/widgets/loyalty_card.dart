import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/loyalty_info.dart';

/// Loyalty card widget for profile screen
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
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _tierColor.withValues(alpha: 0.3),
                _tierColor.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: _tierColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loyalty Rewards',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _tierColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        loyaltyInfo.currentTier.name.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Points balance
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Points',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            numberFormat.format(loyaltyInfo.pointsBalance),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Lifetime Points',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            numberFormat.format(loyaltyInfo.lifetimePoints),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Progress to next tier
                if (loyaltyInfo.nextTier != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to ${loyaltyInfo.nextTier!.name.toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        loyaltyInfo.pointsToNextTier > 0
                            ? '${numberFormat.format(loyaltyInfo.pointsToNextTier)} pts to go'
                            : 'Almost there!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _tierColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loyaltyInfo.progressToNextTier,
                      backgroundColor: _tierColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
                      minHeight: 8,
                    ),
                  ),
                ],

                // View details hint
                if (onTap != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'View history',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _tierColor,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: _tierColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state when user has no loyalty account
class LoyaltyEmptyCard extends StatelessWidget {
  const LoyaltyEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Join our Loyalty Program',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Earn points on every purchase and unlock exclusive rewards!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state for loyalty card
class LoyaltyLoadingCard extends StatelessWidget {
  const LoyaltyLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}
