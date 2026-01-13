import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/loyalty_account.dart';
import '../models/points_transaction.dart';
import '../providers/loyalty_provider.dart';

class LoyaltyAccountDetailScreen extends ConsumerStatefulWidget {
  final LoyaltyAccount account;
  final ScrollController? scrollController;

  const LoyaltyAccountDetailScreen({
    super.key,
    required this.account,
    this.scrollController,
  });

  @override
  ConsumerState<LoyaltyAccountDetailScreen> createState() => _LoyaltyAccountDetailScreenState();
}

class _LoyaltyAccountDetailScreenState extends ConsumerState<LoyaltyAccountDetailScreen> {
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

  Color get _tierColor {
    switch (widget.account.currentTier) {
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
    final dateFormat = DateFormat.MMMd().add_jm();

    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium, color: _tierColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Details',
                      style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'User: ${widget.account.userId}',
                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Stats row
              Row(
                children: [
                  _StatItem(
                    label: 'Balance',
                    value: numberFormat.format(widget.account.pointsBalance),
                  ),
                  _StatItem(
                    label: 'Lifetime',
                    value: numberFormat.format(widget.account.lifetimePoints),
                  ),
                  _StatItem(
                    label: 'Tier',
                    value: widget.account.currentTier.name.toUpperCase(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddPointsDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Points'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colors.primary,
                          foregroundColor: theme.colors.primaryForeground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAdjustPointsDialog(context),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Adjust'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colors.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Transactions section
              Row(
                children: [
                  Text(
                    'Transactions',
                    style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadTransactions,
                    child: Icon(Icons.refresh, size: 18, color: theme.colors.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_transactions.isEmpty)
                _EmptyState()
              else
                ..._transactions.map((tx) => _TransactionTile(
                  transaction: tx,
                  dateFormat: dateFormat,
                  numberFormat: numberFormat,
                )),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddPointsDialog(BuildContext context) {
    final pointsController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Points',
              style: context.theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final points = int.tryParse(pointsController.text);
                      if (points == null || points <= 0) return;
                      Navigator.pop(context);
                      await ref.read(loyaltyProvider.notifier).earnPoints(
                        userId: widget.account.userId,
                        points: points,
                        type: 'bonus',
                        description: descriptionController.text.isEmpty
                            ? 'Manual bonus'
                            : descriptionController.text,
                      );
                      _loadTransactions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.colors.primary,
                      foregroundColor: context.theme.colors.primaryForeground,
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAdjustPointsDialog(BuildContext context) {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjust Points',
              style: context.theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Use positive to add, negative to deduct',
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(
                labelText: 'Points (e.g., 100 or -50)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final points = int.tryParse(pointsController.text);
                      if (points == null || points == 0) return;
                      Navigator.pop(context);
                      await ref.read(loyaltyProvider.notifier).adjustPoints(
                        userId: widget.account.userId,
                        points: points,
                        reason: reasonController.text.isEmpty
                            ? 'Manual adjustment'
                            : reasonController.text,
                      );
                      _loadTransactions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.colors.primary,
                      foregroundColor: context.theme.colors.primaryForeground,
                    ),
                    child: const Text('Adjust'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 40, color: theme.colors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PointsTransaction transaction;
  final DateFormat dateFormat;
  final NumberFormat numberFormat;

  const _TransactionTile({
    required this.transaction,
    required this.dateFormat,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isPositive = transaction.isEarned;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              size: 18,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeDisplay,
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  dateFormat.format(transaction.createdAt.toLocal()),
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${numberFormat.format(transaction.points)}',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
