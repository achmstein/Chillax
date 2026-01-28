import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/ui_components.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final theme = context.theme;

    return Column(
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Pending Orders',
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.orders.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.orders.length}',
                    style: theme.typography.xs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () => ref.read(ordersProvider.notifier).loadOrders(),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Error
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 18, color: theme.colors.destructive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: theme.typography.sm.copyWith(color: theme.colors.destructive),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Content
        Expanded(
          child: state.isLoading && state.orders.isEmpty
              ? const ShimmerLoadingList()
              : state.orders.isEmpty
                  ? EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'No pending orders',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
                      child: ListView.separated(
                        padding: kScreenPadding,
                        itemCount: state.orders.length,
                        separatorBuilder: (_, __) => const FDivider(),
                        itemBuilder: (context, index) {
                          final order = state.orders[index];
                          return _OrderTile(
                            order: order,
                            onConfirm: () => _confirmOrder(order.id),
                            onCancel: () => _cancelOrder(context, order.id),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    await ref.read(ordersProvider.notifier).confirmOrder(orderId);
  }

  Future<void> _cancelOrder(BuildContext context, int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(ordersProvider.notifier).cancelOrder(orderId);
    }
  }
}

class _OrderTile extends ConsumerStatefulWidget {
  final Order order;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _OrderTile({
    required this.order,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  ConsumerState<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends ConsumerState<_OrderTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final dateFormat = DateFormat('MMM d, h:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - tappable
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${widget.order.id}',
                        style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currencyFormat.format(widget.order.total)} • ${dateFormat.format(widget.order.date)}',
                        style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                if (widget.order.tableNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'T${widget.order.tableNumber}',
                      style: theme.typography.xs,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),

        // Expanded content - fetch details when expanded
        if (_expanded) _buildExpandedContent(theme, currencyFormat),
      ],
    );
  }

  Widget _buildExpandedContent(FThemeData theme, NumberFormat currencyFormat) {
    final orderDetailsAsync = ref.watch(orderDetailsProvider(widget.order.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: orderDetailsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, _) => Text(
          'Failed to load details',
          style: theme.typography.sm.copyWith(color: theme.colors.destructive),
        ),
        data: (orderDetails) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Items
            if (orderDetails.items.isNotEmpty) ...[
              ...orderDetails.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${item.units}x ',
                          style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                        ),
                        Expanded(
                          child: Text(item.productName, style: theme.typography.sm),
                        ),
                        Text(
                          currencyFormat.format(item.totalPrice),
                          style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                        ),
                      ],
                    ),
                    // Customizations
                    if (item.customizationsDescription != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(
                          item.customizationsDescription!,
                          style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                        ),
                      ),
                    // Special instructions
                    if (item.specialInstructions != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(
                          '"${item.specialInstructions}"',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
            ] else
              Text(
                'No items',
                style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
              ),

            // Customer note
            if (orderDetails.customerNote != null) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${orderDetails.customerNote}',
                style: theme.typography.sm.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    style: FButtonStyle.outline(),
                    onPress: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FButton(
                    onPress: widget.onConfirm,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
