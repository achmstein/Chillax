import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/loyalty_account.dart';
import '../models/points_transaction.dart';
import '../providers/loyalty_provider.dart';

class LoyaltyAccountDetailScreen extends ConsumerStatefulWidget {
  final LoyaltyAccount account;

  const LoyaltyAccountDetailScreen({
    super.key,
    required this.account,
  });

  @override
  ConsumerState<LoyaltyAccountDetailScreen> createState() =>
      _LoyaltyAccountDetailScreenState();
}

class _LoyaltyAccountDetailScreenState
    extends ConsumerState<LoyaltyAccountDetailScreen> {
  List<PointsTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final transactions = await ref
        .read(loyaltyProvider.notifier)
        .getTransactions(widget.account.userId);
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Container(
      width: 400,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Account Details',
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const FDivider(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account card
                _AccountSummaryCard(
                  account: widget.account,
                  theme: theme,
                  numberFormat: numberFormat,
                ),
                const SizedBox(height: 24),

                // Actions
                Text(
                  'Actions',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        onPress: () => _showAddPointsDialog(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Add Points'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.outline(),
                        onPress: () => _showAdjustPointsDialog(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Adjust'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Transaction history
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaction History',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _loadTransactions,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: FProgress(),
                    ),
                  )
                else if (_transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            style: theme.typography.base.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._transactions.map((tx) => _TransactionTile(
                        transaction: tx,
                        theme: theme,
                        numberFormat: numberFormat,
                        dateFormat: dateFormat,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPointsDialog(BuildContext context) {
    final pointsController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'bonus';

    showAdaptiveDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => FDialog(
          direction: Axis.vertical,
          title: const Text('Add Points'),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  hintText: 'Enter points amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'bonus', child: Text('Bonus')),
                  DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
                  DropdownMenuItem(value: 'referral', child: Text('Referral')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter reason for adding points',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            FButton(
              style: FButtonStyle.outline(),
              onPress: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FButton(
              onPress: () async {
                final points = int.tryParse(pointsController.text);
                if (points == null || points <= 0) {
                  return;
                }
                Navigator.of(context).pop();
                await ref.read(loyaltyProvider.notifier).earnPoints(
                      userId: widget.account.userId,
                      points: points,
                      type: selectedType,
                      description: descriptionController.text.isEmpty
                          ? 'Manual bonus'
                          : descriptionController.text,
                    );
                _loadTransactions();
              },
              child: const Text('Add Points'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustPointsDialog(BuildContext context) {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();

    showAdaptiveDialog<void>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.vertical,
        title: const Text('Adjust Points'),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a positive number to add points, or negative to deduct.',
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(
                labelText: 'Points Adjustment',
                hintText: 'e.g., 100 or -50',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter reason for adjustment',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FButton(
            onPress: () async {
              final points = int.tryParse(pointsController.text);
              if (points == null || points == 0) {
                return;
              }
              Navigator.of(context).pop();
              await ref.read(loyaltyProvider.notifier).adjustPoints(
                    userId: widget.account.userId,
                    points: points,
                    reason: reasonController.text.isEmpty
                        ? 'Manual adjustment'
                        : reasonController.text,
                  );
              _loadTransactions();
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  final LoyaltyAccount account;
  final FThemeData theme;
  final NumberFormat numberFormat;

  const _AccountSummaryCard({
    required this.account,
    required this.theme,
    required this.numberFormat,
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
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tier badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _tierColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                color: _tierColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 12),
            FBadge(
              style: FBadgeStyle.secondary(),
              child: Text(account.currentTier.name.toUpperCase()),
            ),
            const SizedBox(height: 20),
            // Points
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Available',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        numberFormat.format(account.pointsBalance),
                        style: theme.typography.xl2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'points',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: theme.colors.border,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Lifetime',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        numberFormat.format(account.lifetimePoints),
                        style: theme.typography.xl2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'points',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Next tier progress
            if (account.nextTier != null && account.pointsToNextTier > 0) ...[
              const SizedBox(height: 20),
              Text(
                '${numberFormat.format(account.pointsToNextTier)} points to ${account.nextTier!.name.toUpperCase()}',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PointsTransaction transaction;
  final FThemeData theme;
  final NumberFormat numberFormat;
  final DateFormat dateFormat;

  const _TransactionTile({
    required this.transaction,
    required this.theme,
    required this.numberFormat,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.isEarned;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.typeDisplay,
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${numberFormat.format(transaction.points)}',
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.description,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dateFormat.format(transaction.createdAt.toLocal()),
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
