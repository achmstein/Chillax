import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/ui_components.dart';
import '../../customers/models/customer.dart';
import '../models/customer_account.dart';
import '../providers/accounts_provider.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(accountsProvider.notifier).loadAccounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);
    final notifier = ref.read(accountsProvider.notifier);
    final theme = context.theme;
    final filteredAccounts = notifier.filteredAccounts;

    return Column(
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Accounts',
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _showAddChargeDialog(context),
                tooltip: 'Add charge',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () => notifier.loadAccounts(),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
              prefixIcon: Icon(Icons.search, size: 20, color: theme.colors.mutedForeground),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: theme.typography.sm,
            onChanged: (value) => notifier.setSearchQuery(value),
          ),
        ),

        // Content
        Expanded(
          child: state.isLoading && state.accounts.isEmpty
              ? const ShimmerLoadingList()
              : RefreshIndicator(
                  onRefresh: () => notifier.loadAccounts(),
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

                      // Stats summary
                      _StatsSummary(accounts: state.accounts),
                      const SizedBox(height: 24),

                      // Accounts section
                      SectionHeader(
                        title: 'Outstanding Balances',
                        count: filteredAccounts.length,
                      ),
                      const SizedBox(height: 8),

                      // Accounts list
                      if (filteredAccounts.isEmpty)
                        const EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No accounts with balance',
                          subtitle: 'Add a charge to create an account',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAccounts.length,
                          separatorBuilder: (_, __) => const FDivider(),
                          itemBuilder: (context, index) {
                            final account = filteredAccounts[index];
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

  void _showAddChargeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.theme.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _AddChargeSheet(scrollController: scrollController),
        ),
      ),
    );
  }

  void _showAccountDetail(BuildContext context, CustomerAccount account) {
    // Load account details first
    ref.read(accountsProvider.notifier).selectAccount(account.customerId);

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
          child: _AccountDetailSheet(
            account: account,
            scrollController: scrollController,
          ),
        ),
      ),
    ).whenComplete(() {
      ref.read(accountsProvider.notifier).clearSelectedAccount();
    });
  }
}

class _StatsSummary extends StatelessWidget {
  final List<CustomerAccount> accounts;

  const _StatsSummary({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);

    final totalBalance = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    final accountsWithBalance = accounts.where((a) => a.balance > 0).length;

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
            _StatItem(
              label: 'Total Owed',
              value: currencyFormat.format(totalBalance),
              valueColor: totalBalance > 0 ? theme.colors.destructive : null,
            ),
            _StatItem(
              label: 'Accounts',
              value: '${accounts.length}',
            ),
            _StatItem(
              label: 'With Balance',
              value: '$accountsWithBalance',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
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

class _AccountTile extends StatelessWidget {
  final CustomerAccount account;
  final VoidCallback onTap;

  const _AccountTile({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);

    return FTappable(
      onPress: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: account.hasBalance
                    ? theme.colors.destructive.withValues(alpha: 0.1)
                    : theme.colors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  account.displayName.isNotEmpty
                      ? account.displayName[0].toUpperCase()
                      : '?',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                    color: account.hasBalance
                        ? theme.colors.destructive
                        : theme.colors.foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName,
                    style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${_formatDate(account.updatedAt)}',
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),
            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(account.balance),
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: account.hasBalance ? theme.colors.destructive : theme.colors.foreground,
                  ),
                ),
                if (account.hasBalance)
                  Text(
                    'owes',
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: theme.colors.mutedForeground),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

/// Sheet for adding a charge to a customer
class _AddChargeSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _AddChargeSheet({required this.scrollController});

  @override
  ConsumerState<_AddChargeSheet> createState() => _AddChargeSheetState();
}

class _AddChargeSheetState extends ConsumerState<_AddChargeSheet> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);
    final theme = context.theme;

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Add Charge',
                style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, size: 24, color: theme.colors.mutedForeground),
              ),
            ],
          ),
        ),
        const FDivider(),

        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: kScreenPadding,
            children: [
              // Customer selection
              Text(
                'Customer',
                style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              if (_selectedCustomer == null) ...[
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customer by name...',
                    hintStyle: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                    prefixIcon: Icon(Icons.search, size: 20, color: theme.colors.mutedForeground),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  style: theme.typography.sm,
                  onChanged: (value) {
                    ref.read(accountsProvider.notifier).searchUsers(value);
                  },
                ),
                const SizedBox(height: 8),

                // Search results
                if (state.isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) {
                        final customer = state.searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colors.secondary,
                            child: Text(
                              customer.initials,
                              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          title: Text(customer.displayName, style: theme.typography.sm),
                          subtitle: customer.email != null
                              ? Text(customer.email!,
                                  style: theme.typography.xs
                                      .copyWith(color: theme.colors.mutedForeground))
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCustomer = customer;
                              _searchController.clear();
                            });
                            ref.read(accountsProvider.notifier).clearSearchResults();
                          },
                        );
                      },
                    ),
                  ),
              ] else ...[
                // Selected customer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colors.primary.withValues(alpha: 0.1),
                        child: Text(
                          _selectedCustomer!.initials,
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCustomer!.displayName,
                              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (_selectedCustomer!.email != null)
                              Text(
                                _selectedCustomer!.email!,
                                style: theme.typography.xs
                                    .copyWith(color: theme.colors.mutedForeground),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCustomer = null;
                          });
                        },
                        child: Icon(Icons.close, size: 20, color: theme.colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Amount
              Text(
                'Amount (EGP)',
                style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                  prefixText: 'EGP ',
                  prefixStyle: theme.typography.sm,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: theme.typography.sm,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                'Description (optional)',
                style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., Remaining from session - Room 3',
                  hintStyle: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: theme.typography.sm,
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: _selectedCustomer != null && !_isSubmitting
                      ? _submitCharge
                      : null,
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colors.primaryForeground,
                          ),
                        )
                      : const Text('Add Charge'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitCharge() async {
    if (_selectedCustomer == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(accountsProvider.notifier).addCharge(
          customerId: _selectedCustomer!.id,
          amount: amount,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          customerName: _selectedCustomer!.displayName,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Charge added successfully')),
      );
    }
  }
}

/// Sheet for viewing account details
class _AccountDetailSheet extends ConsumerStatefulWidget {
  final CustomerAccount account;
  final ScrollController scrollController;

  const _AccountDetailSheet({
    required this.account,
    required this.scrollController,
  });

  @override
  ConsumerState<_AccountDetailSheet> createState() => _AccountDetailSheetState();
}

class _AccountDetailSheetState extends ConsumerState<_AccountDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);

    final account = state.selectedAccount ?? widget.account;
    final transactions = state.selectedAccountTransactions ?? [];

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colors.secondary,
                child: Text(
                  account.displayName.isNotEmpty
                      ? account.displayName[0].toUpperCase()
                      : '?',
                  style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Balance: ${currencyFormat.format(account.balance)}',
                      style: theme.typography.sm.copyWith(
                        color: account.hasBalance
                            ? theme.colors.destructive
                            : theme.colors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, size: 24, color: theme.colors.mutedForeground),
              ),
            ],
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: FButton(
                  style: FButtonStyle.outline(),
                  onPress: () => _showAddChargeToExisting(context, account),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 4),
                      Text('Add Charge'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FButton(
                  onPress: account.hasBalance
                      ? () => _showRecordPayment(context, account)
                      : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 18),
                      SizedBox(width: 4),
                      Text('Record Payment'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const FDivider(),

        // Transactions
        Expanded(
          child: state.isLoadingTransactions
              ? const ShimmerLoadingList(itemCount: 3)
              : transactions.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                    )
                  : ListView.separated(
                      controller: widget.scrollController,
                      padding: kScreenPadding,
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const FDivider(),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return _TransactionTile(transaction: tx);
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddChargeToExisting(BuildContext context, CustomerAccount account) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => _AmountDialog(
        title: 'Add Charge',
        account: account,
        isPayment: false,
      ),
    );
  }

  void _showRecordPayment(BuildContext context, CustomerAccount account) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => _AmountDialog(
        title: 'Record Payment',
        account: account,
        isPayment: true,
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final AccountTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    final isCharge = transaction.type == TransactionType.charge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isCharge ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCharge ? Icons.add : Icons.remove,
              size: 20,
              color: isCharge ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCharge ? 'Charge' : 'Payment',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${isCharge ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCharge ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (transaction.description != null && transaction.description!.isNotEmpty)
                  Text(
                    transaction.description!,
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(transaction.createdAt)} by ${transaction.recordedBy}',
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding charge or recording payment
class _AmountDialog extends ConsumerStatefulWidget {
  final String title;
  final CustomerAccount account;
  final bool isPayment;

  const _AmountDialog({
    required this.title,
    required this.account,
    required this.isPayment,
  });

  @override
  ConsumerState<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends ConsumerState<_AmountDialog> {
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
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);

    return FDialog(
      direction: Axis.horizontal,
      title: Text(widget.title),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isPayment) ...[
            Text(
              'Current balance: ${currencyFormat.format(widget.account.balance)}',
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (EGP)',
              hintText: '0.00',
              prefixText: 'EGP ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.primary),
              ),
            ),
            style: theme.typography.sm,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: widget.isPayment ? 'e.g., Cash payment' : 'e.g., Remaining from session',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.primary),
              ),
            ),
            style: theme.typography.sm,
          ),
        ],
      ),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FButton(
          style: widget.isPayment ? FButtonStyle.primary() : FButtonStyle.destructive(),
          onPress: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colors.primaryForeground,
                  ),
                )
              : Text(widget.isPayment ? 'Record Payment' : 'Add Charge'),
        ),
      ],
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
          );
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isPayment
              ? 'Payment recorded successfully'
              : 'Charge added successfully'),
        ),
      );
    }
  }
}
