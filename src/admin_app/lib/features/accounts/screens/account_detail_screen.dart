import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/customer_account.dart';
import '../providers/accounts_provider.dart';

class AccountDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const AccountDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(accountsProvider.notifier).selectAccount(widget.customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);
    final theme = context.theme;

    final account = state.selectedAccount ??
        state.accounts.where((a) => a.customerId == widget.customerId).firstOrNull;
    final transactions = state.selectedAccountTransactions ?? [];

    if (account == null && state.isLoadingTransactions) {
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

    if (account == null) {
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

    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final hasBalance = account.hasBalance;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with name
            _buildHeader(context, theme, account),

            // Balance and actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  // Balance label
                  Text(
                    'Balance',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Balance amount
                  Text(
                    currencyFormat.format(account.balance),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: hasBalance ? const Color(0xFFEF4444) : theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons - full width, side by side
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => _showAddCharge(context, account),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 8),
                              Text('Charge'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FButton(
                          onPress: hasBalance ? () => _showRecordPayment(context, account) : null,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payments_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Payment'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // History section
            Expanded(
              child: _TransactionHistorySection(
                transactions: transactions,
                isLoading: state.isLoadingTransactions,
                onRefresh: () => ref
                    .read(accountsProvider.notifier)
                    .selectAccount(widget.customerId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FThemeData theme, CustomerAccount? account) {
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
              account?.displayName ?? 'Account',
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (account != null)
            IconButton(
              icon: const Icon(Icons.person_outline, size: 22),
              onPressed: () => context.go('/customers/${account.customerId}'),
              tooltip: 'View Customer',
            ),
        ],
      ),
    );
  }

  void _showAddCharge(BuildContext context, CustomerAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _AmountSheet(
        title: 'Add Charge',
        account: account,
        isPayment: false,
        onComplete: () {
          ref.read(accountsProvider.notifier).selectAccount(widget.customerId);
        },
      ),
    );
  }

  void _showRecordPayment(BuildContext context, CustomerAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _AmountSheet(
        title: 'Record Payment',
        account: account,
        isPayment: true,
        onComplete: () {
          ref.read(accountsProvider.notifier).selectAccount(widget.customerId);
        },
      ),
    );
  }
}

class _TransactionHistorySection extends StatelessWidget {
  final List<AccountTransaction> transactions;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _TransactionHistorySection({
    required this.transactions,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');

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
                      child: Text(
                        'No transactions yet',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isCharge = tx.type == TransactionType.charge;

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
                                    isCharge ? Icons.arrow_upward : Icons.arrow_downward,
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
                                        tx.description?.isNotEmpty == true
                                            ? tx.description!
                                            : (isCharge ? 'Charge' : 'Payment'),
                                        style: theme.typography.sm.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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

                                // Amount
                                Text(
                                  '${isCharge ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                  style: theme.typography.sm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isCharge
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF22C55E),
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

class _AmountSheet extends ConsumerStatefulWidget {
  final String title;
  final CustomerAccount account;
  final bool isPayment;
  final VoidCallback? onComplete;

  const _AmountSheet({
    required this.title,
    required this.account,
    required this.isPayment,
    this.onComplete,
  });

  @override
  ConsumerState<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends ConsumerState<_AmountSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

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
                    // Current balance (for payments)
                    if (widget.isPayment) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
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
                              currencyFormat.format(widget.account.balance),
                              style: theme.typography.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amount
                    Text(
                      'Amount (EGP)',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(controller: _amountController),
                      hint: '0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Description',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    FTextField.multiline(
                      control: FTextFieldControl.managed(controller: _descriptionController),
                      hint: widget.isPayment ? 'e.g., Cash payment' : 'e.g., Session balance',
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
                      style: widget.isPayment
                          ? FButtonStyle.primary()
                          : FButtonStyle.destructive(),
                      onPress: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isPayment ? 'Record' : 'Add Charge'),
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
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success;
    if (widget.isPayment) {
      success = await ref.read(accountsProvider.notifier).recordPayment(
            customerId: widget.account.customerId,
            amount: amount,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
          );
    } else {
      success = await ref.read(accountsProvider.notifier).addCharge(
            customerId: widget.account.customerId,
            amount: amount,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            customerName: widget.account.displayName,
          );
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        widget.onComplete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isPayment ? 'Payment recorded' : 'Charge added'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isPayment ? 'Failed to record payment' : 'Failed to add charge'),
          ),
        );
      }
    }
  }
}
