import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_scaffold.dart';
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
    _searchController.addListener(_onSearchChanged);

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/accounts' && previous != '/accounts' && previous != null) {
        ref.read(accountsProvider.notifier).loadAccounts();
      }
    });
  }

  void _onSearchChanged() {
    ref.read(accountsProvider.notifier).setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);
    final notifier = ref.read(accountsProvider.notifier);
    final theme = context.theme;
    final filteredAccounts = notifier.filteredAccounts;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final totalBalance = state.accounts.fold<double>(0, (sum, a) => sum + a.balance);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('Accounts', style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _showAddChargeDialog(context),
                tooltip: 'Add charge',
              ),
            ],
          ),
        ),

        // Total outstanding
        if (state.accounts.isNotEmpty && totalBalance > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Outstanding',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(totalBalance),
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FTextField(
            control: FTextFieldControl.managed(controller: _searchController),
            hint: 'Search by name...',
          ),
        ),

        const SizedBox(height: 8),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.accounts.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: filteredAccounts.isEmpty
                ? const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No accounts found',
                    subtitle: 'Add a charge to create an account',
                  )
                : RefreshIndicator(
                    onRefresh: () => notifier.loadAccounts(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final account = filteredAccounts[index];
                        return _AccountTile(
                          account: account,
                          onTap: () => _showAccountDetail(context, account),
                        );
                      },
                    ),
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const _AddChargeSheet(),
    );
  }

  void _showAccountDetail(BuildContext context, CustomerAccount account) {
    context.go('/accounts/${account.customerId}');
  }
}

class _AccountTile extends StatelessWidget {
  final CustomerAccount account;
  final VoidCallback onTap;

  const _AccountTile({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  account.displayName.isNotEmpty
                      ? account.displayName[0].toUpperCase()
                      : '?',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
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
                    style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(account.updatedAt),
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),
            // Balance
            Text(
              currencyFormat.format(account.balance),
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: account.hasBalance ? theme.colors.destructive : theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

/// Sheet for adding a charge to a customer
class _AddChargeSheet extends ConsumerStatefulWidget {
  const _AddChargeSheet();

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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);
    final theme = context.theme;

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
                      'Add Charge',
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
                    // Customer selection
                    Text(
                      'Customer *',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    if (_selectedCustomer == null) ...[
                      // Search field
                      FTextField(
                        control: FTextFieldControl.managed(controller: _searchController),
                        hint: 'Search customer by name...',
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
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: theme.colors.secondary,
                                  child: Text(
                                    customer.initials,
                                    style: theme.typography.xs.copyWith(fontWeight: FontWeight.w600),
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
                              radius: 16,
                              backgroundColor: theme.colors.primary.withValues(alpha: 0.1),
                              child: Text(
                                _selectedCustomer!.initials,
                                style: theme.typography.xs.copyWith(
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

                    const SizedBox(height: 16),

                    // Amount
                    Text(
                      'Amount (EGP) *',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(controller: _amountController),
                      hint: '0.00',
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
                      hint: 'e.g., Remaining from session - Room 3',
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
                      onPress: _selectedCustomer != null && !_isSubmitting
                          ? _submitCharge
                          : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Charge'),
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

  void _onSearchChanged() {
    ref.read(accountsProvider.notifier).searchUsers(_searchController.text);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Charge added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add charge')),
        );
      }
    }
  }
}
