import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_stats.dart';
import '../providers/loyalty_provider.dart';

/// Helper function to get localized tier name
String getLocalizedTierName(LoyaltyTier tier, AppLocalizations l10n) {
  switch (tier) {
    case LoyaltyTier.bronze:
      return l10n.tierBronze;
    case LoyaltyTier.silver:
      return l10n.tierSilver;
    case LoyaltyTier.gold:
      return l10n.tierGold;
    case LoyaltyTier.platinum:
      return l10n.tierPlatinum;
  }
}

/// Helper function to get localized tier name from string
String getLocalizedTierNameFromString(String tierName, AppLocalizations l10n) {
  switch (tierName.toLowerCase()) {
    case 'bronze':
      return l10n.tierBronze;
    case 'silver':
      return l10n.tierSilver;
    case 'gold':
      return l10n.tierGold;
    case 'platinum':
      return l10n.tierPlatinum;
    default:
      return tierName;
  }
}

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(loyaltyProvider.notifier).loadAll();
    });

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/loyalty' && previous != '/loyalty' && previous != null) {
        ref.read(loyaltyProvider.notifier).loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loyaltyProvider);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AppText(l10n.loyalty, style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.accounts.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: RefreshIndicator(
              onRefresh: () => ref.read(loyaltyProvider.notifier).loadAll(),
              child: ListView(
                padding: kScreenPadding,
                children: [
                  // Stats
                  if (state.stats != null) ...[
                    _StatsSection(stats: state.stats!),
                    const SizedBox(height: 24),
                  ],

                  // Tiers
                  if (state.tiers.isNotEmpty) ...[
                    _TierSection(tiers: state.tiers, stats: state.stats),
                    const SizedBox(height: 24),
                  ],

                  // Accounts section
                  SectionHeader(
                    title: l10n.accountsLabel,
                    count: state.accounts.length,
                  ),
                  const SizedBox(height: 8),

                  // Accounts list
                  if (state.accounts.isEmpty)
                    EmptyState(
                      icon: Icons.card_giftcard_outlined,
                      title: l10n.noLoyaltyAccounts,
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.accounts.length,
                      separatorBuilder: (_, __) => const FDivider(),
                      itemBuilder: (context, index) {
                        final account = state.accounts[index];
                        return _AccountTile(
                          account: account,
                          onTap: () => _showAccountDetail(context, account),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAccountDetail(BuildContext context, LoyaltyAccount account) {
    context.go(
      '/loyalty/account/${account.userId}',
      extra: account.toJson(),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final LoyaltyStats stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.compact();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          l10n.overview,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatItem(label: l10n.accountsLabel, value: numberFormat.format(stats.totalAccounts)),
            _StatItem(label: l10n.todayLabel, value: numberFormat.format(stats.pointsIssuedToday)),
            _StatItem(label: l10n.weekLabel, value: numberFormat.format(stats.pointsIssuedThisWeek)),
            _StatItem(label: l10n.monthLabel, value: numberFormat.format(stats.pointsIssuedThisMonth)),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Expanded(
      child: Column(
        children: [
          AppText(
            value,
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
          ),
          AppText(
            label,
            style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _TierSection extends StatelessWidget {
  final List<TierInfo> tiers;
  final LoyaltyStats? stats;

  const _TierSection({required this.tiers, this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          l10n.tiers,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: tiers.map((tier) {
            final count = stats?.getCountForTier(tier.name) ?? 0;
            return Expanded(
              child: _TierItem(tier: tier, count: count),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TierItem extends StatelessWidget {
  final TierInfo tier;
  final int count;

  const _TierItem({required this.tier, required this.count});

  LoyaltyTier get _loyaltyTier => LoyaltyTier.fromString(tier.name);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final tierColor = Color(_loyaltyTier.colorValue);

    return Column(
      children: [
        Icon(Icons.workspace_premium, size: 24, color: tierColor),
        const SizedBox(height: 4),
        AppText(
          getLocalizedTierNameFromString(tier.name, l10n),
          style: theme.typography.xs.copyWith(fontWeight: FontWeight.w600),
        ),
        AppText(
          '$count',
          style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final LoyaltyAccount account;
  final VoidCallback onTap;

  const _AccountTile({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,###');
    final gradientColors = account.currentTier.gradientColors.map((c) => Color(c)).toList();
    final tierColor = Color(account.currentTier.colorValue);
    // Use white icon for darker tiers, dark icon for lighter tiers
    final iconColor = (account.currentTier == LoyaltyTier.bronze || account.currentTier == LoyaltyTier.platinum)
        ? Colors.white
        : Colors.black87;

    return FTappable(
      onPress: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Tier icon with gradient
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.workspace_premium, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          account.displayName,
                          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AppText(
                          getLocalizedTierName(account.currentTier, l10n),
                          style: theme.typography.xs.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${numberFormat.format(account.pointsBalance)} ${l10n.points} • ${numberFormat.format(account.lifetimePoints)} ${l10n.lifetime}',
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
