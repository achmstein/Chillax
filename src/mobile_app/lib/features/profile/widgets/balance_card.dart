import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/account_provider.dart';

/// Balance card widget for profile screen
/// Only shown when customer has outstanding balance
class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({super.key});

  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> {
  @override
  void initState() {
    super.initState();
    // Load account on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).loadAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);

    // Don't show if loading, no account, or zero balance
    if (accountState.isLoading) {
      return const SizedBox.shrink();
    }

    final account = accountState.account;
    if (account == null || !account.hasBalance) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.push('/transactions'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: account.owesAmount
                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                : [const Color(0xFF10B981), const Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (account.owesAmount ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  account.owesAmount ? FIcons.circleAlert : FIcons.check,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  account.owesAmount ? 'Amount Due' : 'Credit Balance',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  FIcons.chevronRight,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${account.balance.abs().toStringAsFixed(2)} EGP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              account.owesAmount
                  ? 'Please pay at the counter'
                  : 'Will be applied to your next purchase',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
