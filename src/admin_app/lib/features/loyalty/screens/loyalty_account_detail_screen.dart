import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/loyalty_account.dart';
import '../models/points_transaction.dart';
import '../providers/loyalty_provider.dart';

/// Wrapper for loyalty account detail as a full page
class LoyaltyAccountDetailPageWrapper extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic>? accountJson;

  const LoyaltyAccountDetailPageWrapper({
    super.key,
    required this.userId,
    this.accountJson,
  });

  @override
  ConsumerState<LoyaltyAccountDetailPageWrapper> createState() => _LoyaltyAccountDetailPageWrapperState();
}

class _LoyaltyAccountDetailPageWrapperState extends ConsumerState<LoyaltyAccountDetailPageWrapper> {
  LoyaltyAccount? _account;
  bool _isLoading = true;
  List<PointsTransaction> _transactions = [];
  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    if (widget.accountJson != null) {
      setState(() {
        _account = LoyaltyAccount.fromJson(widget.accountJson!);
        _isLoading = false;
      });
      _loadTransactions();
    } else {
      await ref.read(loyaltyProvider.notifier).loadAll();
      final accounts = ref.read(loyaltyProvider).accounts;
      final account = accounts.where((a) => a.userId == widget.userId).firstOrNull;
      setState(() {
        _account = account;
        _isLoading = false;
      });
      if (account != null) {
        _loadTransactions();
      }
    }
  }

  Future<void> _loadTransactions() async {
    if (_account == null) return;
    setState(() => _isLoadingTransactions = true);
    final transactions = await ref
        .read(loyaltyProvider.notifier)
        .getTransactions(_account!.userId);
    setState(() {
      _transactions = transactions;
      _isLoadingTransactions = false;
    });
  }

  Future<void> _refresh() async {
    await _loadAccount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final numberFormat = NumberFormat('#,###');

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme, null),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    if (_account == null) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme, null),
              Expanded(
                child: Center(
                  child: Text(
                    'Account not found',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with name
            _buildHeader(context, theme, _account),

            // Points balance and actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  // Points label
                  Text(
                    'Points Balance',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Points amount
                  Text(
                    numberFormat.format(_account!.pointsBalance),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tier and lifetime
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TierBadge(tier: _account!.currentTier),
                      const SizedBox(width: 12),
                      Text(
                        '${numberFormat.format(_account!.lifetimePoints)} lifetime',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => _showAdjustPointsSheet(context),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: FButton(
                          onPress: () => _showAddPointsSheet(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 8),
                              Text('Add Points'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transactions section
            Expanded(
              child: _TransactionsSection(
                transactions: _transactions,
                isLoading: _isLoadingTransactions,
                onRefresh: _refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FThemeData theme, LoyaltyAccount? account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              account?.displayName ?? 'Loyalty Account',
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (account != null)
            IconButton(
              icon: const Icon(Icons.person_outline, size: 22),
              onPressed: () => context.push('/customers/${account.userId}'),
              tooltip: 'View Customer',
            ),
        ],
      ),
    );
  }

  void _showAddPointsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _PointsSheet(
        title: 'Add Points',
        account: _account!,
        isAdjustment: false,
        onComplete: () => _loadTransactions(),
      ),
    );
  }

  void _showAdjustPointsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _PointsSheet(
        title: 'Adjust Points',
        account: _account!,
        isAdjustment: true,
        onComplete: () => _loadTransactions(),
      ),
    );
  }
}

// Keep old class for backward compatibility but redirect to new implementation
class LoyaltyAccountDetailScreen extends StatelessWidget {
  final LoyaltyAccount account;
  final ScrollController? scrollController;

  const LoyaltyAccountDetailScreen({
    super.key,
    required this.account,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect to the page wrapper
    return LoyaltyAccountDetailPageWrapper(
      userId: account.userId,
      accountJson: account.toJson(),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final LoyaltyTier tier;

  const _TierBadge({required this.tier});

  Color get _tierColor {
    switch (tier) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tierColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 14, color: _tierColor),
          const SizedBox(width: 4),
          Text(
            tier.name.toUpperCase(),
            style: theme.typography.xs.copyWith(
              fontWeight: FontWeight.w600,
              color: _tierColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsSection extends StatelessWidget {
  final List<PointsTransaction> transactions;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _TransactionsSection({
    required this.transactions,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');
    final numberFormat = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            'History',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),

        // List
        Expanded(
          child: isLoading && transactions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isPositive = tx.isEarned;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                // Type indicator
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: theme.colors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isPositive ? Icons.add : Icons.remove,
                                    size: 16,
                                    color: theme.colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Description and date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.typeDisplay,
                                        style: theme.typography.sm.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dateFormat.format(tx.createdAt.toLocal())} at ${timeFormat.format(tx.createdAt.toLocal())}',
                                        style: theme.typography.xs.copyWith(
                                          color: theme.colors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Points
                                Text(
                                  '${isPositive ? '+' : ''}${numberFormat.format(tx.points)}',
                                  style: theme.typography.sm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isPositive
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _PointsSheet extends ConsumerStatefulWidget {
  final String title;
  final LoyaltyAccount account;
  final bool isAdjustment;
  final VoidCallback? onComplete;

  const _PointsSheet({
    required this.title,
    required this.account,
    required this.isAdjustment,
    this.onComplete,
  });

  @override
  ConsumerState<_PointsSheet> createState() => _PointsSheetState();
}

class _PointsSheetState extends ConsumerState<_PointsSheet> {
  final _pointsController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pointsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final numberFormat = NumberFormat('#,###');

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),

            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current balance info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Balance',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          Text(
                            '${numberFormat.format(widget.account.pointsBalance)} pts',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Adjustment hint
                    if (widget.isAdjustment) ...[
                      Text(
                        'Use positive to add, negative to deduct',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Points
                    Text(
                      'Points',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(controller: _pointsController),
                      hint: widget.isAdjustment ? 'e.g., 100 or -50' : '0',
                      keyboardType: widget.isAdjustment
                          ? const TextInputType.numberWithOptions(signed: true)
                          : TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      widget.isAdjustment ? 'Reason' : 'Description',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    FTextField.multiline(
                      control: FTextFieldControl.managed(controller: _descriptionController),
                      hint: widget.isAdjustment ? 'e.g., Correction' : 'e.g., Bonus points',
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isAdjustment ? 'Adjust' : 'Add Points'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final points = int.tryParse(_pointsController.text);

    if (widget.isAdjustment) {
      if (points == null || points == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid points amount')),
        );
        return;
      }
    } else {
      if (points == null || points <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid points amount')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    bool success = false;
    try {
      if (widget.isAdjustment) {
        await ref.read(loyaltyProvider.notifier).adjustPoints(
          userId: widget.account.userId,
          points: points,
          reason: _descriptionController.text.isEmpty
              ? 'Manual adjustment'
              : _descriptionController.text,
        );
      } else {
        await ref.read(loyaltyProvider.notifier).earnPoints(
          userId: widget.account.userId,
          points: points,
          type: 'bonus',
          description: _descriptionController.text.isEmpty
              ? 'Manual bonus'
              : _descriptionController.text,
        );
      }
      success = true;
    } catch (e) {
      success = false;
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        widget.onComplete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isAdjustment ? 'Points adjusted' : 'Points added'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isAdjustment ? 'Failed to adjust points' : 'Failed to add points'),
          ),
        );
      }
    }
  }
}
