import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/ui_components.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_stats.dart';
import '../providers/loyalty_provider.dart';
import 'loyalty_account_detail_screen.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loyaltyProvider);
    final theme = context.theme;

    return Column(
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Loyalty',
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () => ref.read(loyaltyProvider.notifier).loadAll(),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: state.isLoading && state.accounts.isEmpty
              ? const ShimmerLoadingList()
              : RefreshIndicator(
                  onRefresh: () => ref.read(loyaltyProvider.notifier).loadAll(),
                  child: ListView(
                    padding: kScreenPadding,
                    children: [
                      // Error
                      if (state.error != null) ...[
                        FAlert(
                          style: FAlertStyle.destructive(),
                          icon: const Icon(Icons.warning),
                          title: const Text('Error'),
                          subtitle: Text(state.error!),
                        ),
                        const SizedBox(height: 16),
                      ],

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
                        title: 'Accounts',
                        count: state.accounts.length,
                      ),
                      const SizedBox(height: 8),

                      // Accounts list
                      if (state.accounts.isEmpty)
                        const EmptyState(
                          icon: Icons.card_giftcard_outlined,
                          title: 'No loyalty accounts yet',
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
      ],
    );
  }

  void _showAccountDetail(BuildContext context, LoyaltyAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.theme.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: LoyaltyAccountDetailScreen(
            account: account,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final LoyaltyStats stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final numberFormat = NumberFormat.compact();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatItem(label: 'Accounts', value: numberFormat.format(stats.totalAccounts)),
            _StatItem(label: 'Today', value: numberFormat.format(stats.pointsIssuedToday)),
            _StatItem(label: 'Week', value: numberFormat.format(stats.pointsIssuedThisWeek)),
            _StatItem(label: 'Month', value: numberFormat.format(stats.pointsIssuedThisMonth)),
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
          Text(
            value,
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiers',
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

  Color get _tierColor {
    switch (tier.name.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      children: [
        Icon(Icons.workspace_premium, size: 24, color: _tierColor),
        const SizedBox(height: 4),
        Text(
          tier.name,
          style: theme.typography.xs.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
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

  Color get _tierColor {
    switch (account.currentTier) {
      case LoyaltyTier.bronze:
        return const Color(0xFFCD7F32);
      case LoyaltyTier.silver:
        return const Color(0xFFC0C0C0);
      case LoyaltyTier.gold:
        return const Color(0xFFFFD700);
      case LoyaltyTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final numberFormat = NumberFormat('#,###');

    return FTappable(
      onPress: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Tier icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _tierColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.workspace_premium, color: _tierColor, size: 22),
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
                        child: Text(
                          'User: ${account.userId}',
                          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          account.currentTier.name.toUpperCase(),
                          style: theme.typography.xs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${numberFormat.format(account.pointsBalance)} pts • ${numberFormat.format(account.lifetimePoints)} lifetime',
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
