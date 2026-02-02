import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../orders/models/order.dart';
import '../../orders/providers/orders_provider.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  List<Order> _orders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customersProvider.notifier).loadCustomers();
      ref.read(accountsProvider.notifier).loadAccounts();
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    final orders = await ref.read(ordersProvider.notifier).getOrdersByUserId(widget.customerId);
    setState(() {
      _orders = orders;
      _isLoadingOrders = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(customersProvider.notifier).loadCustomers(),
      ref.read(accountsProvider.notifier).loadAccounts(),
      _loadOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final accountsState = ref.watch(accountsProvider);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final currencyFormat = NumberFormat.currency(symbol: '£', decimalDigits: 0);

    final customer =
        state.customers.where((c) => c.id == widget.customerId).firstOrNull;

    // Find account for this customer
    final account = accountsState.accounts
        .where((a) => a.customerId == widget.customerId)
        .firstOrNull;

    if (customer == null) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme, null, l10n),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: AppText(
                          l10n.customerNotFound,
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
            _buildHeader(context, theme, customer, l10n),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      // Balance
                      Expanded(
                        child: _StatItem(
                          label: l10n.balance,
                          value: currencyFormat.format(account?.balance ?? 0),
                          valueColor: account?.hasBalance == true
                              ? const Color(0xFFEF4444)
                              : null,
                          onTap: account?.hasBalance == true
                              ? () => context.push('/accounts/${customer.id}')
                              : null,
                        ),
                      ),
                      // Member since
                      if (customer.createdAt != null)
                        Expanded(
                          child: _StatItem(
                            label: l10n.memberSince,
                            value: DateFormat('MMM yyyy', locale.languageCode).format(customer.createdAt!),
                          ),
                        ),
                      // Status
                      Expanded(
                        child: _StatItem(
                          label: l10n.status,
                          value: customer.enabled ? l10n.active : l10n.disabled,
                          valueColor: customer.enabled
                              ? const Color(0xFF22C55E)
                              : theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => context.push('/accounts/${customer.id}'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, size: 18),
                              const SizedBox(width: 8),
                              AppText(l10n.accountTab),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => context.go('/loyalty'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.workspace_premium_outlined, size: 18),
                              const SizedBox(width: 8),
                              AppText(l10n.loyaltyTab),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order history section
            Expanded(
              child: _OrderHistorySection(
                orders: _orders,
                isLoading: _isLoadingOrders,
                onRefresh: _refresh,
                currencyFormat: currencyFormat,
                l10n: l10n,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FThemeData theme, Customer? customer, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/customers'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  customer?.displayName ?? l10n.customer,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (customer?.email != null)
                  AppText(
                    customer!.email!,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (customer != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              onPressed: () => _showChargeSheet(context, customer),
              tooltip: l10n.addCharge,
            ),
        ],
      ),
    );
  }

  void _showChargeSheet(BuildContext context, Customer customer) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colors.mutedForeground,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                AppText(
                  l10n.addCharge,
                  style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                AppText(l10n.amountEgpLabel, style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                FTextField(
                  control: FTextFieldControl.managed(controller: amountController),
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                AppText(l10n.description, style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                FTextField.multiline(
                  control: FTextFieldControl.managed(controller: descriptionController),
                  hint: l10n.optionalDescription,
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.outline(),
                        onPress: () => Navigator.pop(context),
                        child: AppText(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FButton(
                        onPress: () async {
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: AppText(l10n.pleaseEnterValidAmount)),
                            );
                            return;
                          }

                          final success = await ref.read(accountsProvider.notifier).addCharge(
                            customerId: customer.id,
                            amount: amount,
                            description: descriptionController.text.isNotEmpty
                                ? descriptionController.text
                                : null,
                            customerName: customer.displayName,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: AppText(success ? l10n.chargeAdded : l10n.failedToAddCharge),
                              ),
                            );
                          }
                        },
                        child: AppText(l10n.addCharge),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AppText(
            value,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          AppText(
            label,
            style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _OrderHistorySection extends StatelessWidget {
  final List<Order> orders;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final NumberFormat currencyFormat;
  final AppLocalizations l10n;

  const _OrderHistorySection({
    required this.orders,
    required this.isLoading,
    required this.onRefresh,
    required this.currencyFormat,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat('MMM d', locale.languageCode);
    final timeFormat = DateFormat('h:mm a', locale.languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: AppText(
            l10n.orderHistory,
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),

        // List
        Expanded(
          child: isLoading && orders.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          AppText(
                            l10n.noOrdersYet,
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
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                // Status indicator
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(order.status),
                                    size: 16,
                                    color: _getStatusColor(order.status),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Order info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        l10n.orderNumber(order.id),
                                        style: theme.typography.sm.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AppText(
                                        '${dateFormat.format(order.date.toLocal())} at ${timeFormat.format(order.date.toLocal())}',
                                        style: theme.typography.xs.copyWith(
                                          color: theme.colors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Total
                                AppText(
                                  currencyFormat.format(order.total),
                                  style: theme.typography.sm.copyWith(
                                    fontWeight: FontWeight.w600,
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return const Color(0xFF22C55E);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
      case OrderStatus.submitted:
      case OrderStatus.awaitingValidation:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return Icons.check;
      case OrderStatus.cancelled:
        return Icons.close;
      case OrderStatus.submitted:
      case OrderStatus.awaitingValidation:
        return Icons.schedule;
    }
  }
}
