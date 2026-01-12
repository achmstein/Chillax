import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: const Text('Loyalty Program'),
          suffixes: [
            FHeaderAction(
              icon: const Icon(Icons.refresh),
              onPress: () {
                ref.read(loyaltyProvider.notifier).loadAll();
              },
            ),
          ],
        ),
        const FDivider(),

        // Content
        Expanded(
          child: state.isLoading && state.accounts.isEmpty
              ? const Center(child: FProgress())
              : RefreshIndicator(
                  onRefresh: () => ref.read(loyaltyProvider.notifier).loadAll(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats cards
                      if (state.stats != null) ...[
                        _StatsSection(state: state, theme: theme),
                        const SizedBox(height: 24),
                      ],

                      // Tier breakdown
                      if (state.tiers.isNotEmpty) ...[
                        _TierSection(state: state, theme: theme),
                        const SizedBox(height: 24),
                      ],

                      // Error
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: FAlert(
                            style: FAlertStyle.destructive(),
                            icon: const Icon(Icons.warning),
                            title: const Text('Error'),
                            subtitle: Text(state.error!),
                          ),
                        ),

                      // Accounts header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Loyalty Accounts',
                            style: theme.typography.xl.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${state.accounts.length} accounts',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Accounts list
                      if (state.accounts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.card_giftcard_outlined,
                                  size: 64,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No loyalty accounts yet',
                                  style: theme.typography.lg.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Accounts are created when customers earn their first points',
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...state.accounts.map((account) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AccountCard(
                                account: account,
                                onTap: () => _showAccountDetail(context, account),
                              ),
                            )),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _showAccountDetail(BuildContext context, LoyaltyAccount account) {
    showFSheet(
      context: context,
      side: FLayout.rtl,
      builder: (context) => LoyaltyAccountDetailScreen(account: account),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final LoyaltyState state;
  final FThemeData theme;

  const _StatsSection({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact();
    final stats = state.stats!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.typography.xl.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Accounts',
                value: numberFormat.format(stats.totalAccounts),
                icon: Icons.people,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Points Today',
                value: numberFormat.format(stats.pointsIssuedToday),
                icon: Icons.today,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Points This Week',
                value: numberFormat.format(stats.pointsIssuedThisWeek),
                icon: Icons.calendar_view_week,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Points This Month',
                value: numberFormat.format(stats.pointsIssuedThisMonth),
                icon: Icons.calendar_month,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final FThemeData theme;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                Icon(icon, size: 16, color: theme.colors.mutedForeground),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.typography.xl2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierSection extends StatelessWidget {
  final LoyaltyState state;
  final FThemeData theme;

  const _TierSection({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tier Breakdown',
          style: theme.typography.xl.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < state.tiers.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _TierCard(
                  tier: state.tiers[i],
                  count: state.stats?.getCountForTier(state.tiers[i].name) ?? 0,
                  theme: theme,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final TierInfo tier;
  final int count;
  final FThemeData theme;

  const _TierCard({
    required this.tier,
    required this.count,
    required this.theme,
  });

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
        return theme.colors.foreground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium,
              size: 32,
              color: _tierColor,
            ),
            const SizedBox(height: 8),
            Text(
              tier.name,
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count members',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${tier.pointsRequired}+ pts',
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final LoyaltyAccount account;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.onTap,
  });

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

    return FCard(
      child: FTappable(
        onPress: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tier icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: _tierColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
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
                            style: theme.typography.base.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        FBadge(
                          style: FBadgeStyle.secondary(),
                          child: Text(account.currentTier.name.toUpperCase()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${numberFormat.format(account.pointsBalance)} points available',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      '${numberFormat.format(account.lifetimePoints)} lifetime points',
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
