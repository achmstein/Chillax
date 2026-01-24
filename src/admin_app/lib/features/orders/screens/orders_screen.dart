import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int _selectedTab = 0;

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

    final orders = _selectedTab == 0 ? state.orders : state.pendingOrders;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Orders',
                style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(ordersProvider.notifier).loadOrders(),
                child: Icon(Icons.refresh, size: 20, color: theme.colors.mutedForeground),
              ),
            ],
          ),
        ),

        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Tab(
                label: 'All',
                count: state.orders.length,
                isSelected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 16),
              _Tab(
                label: 'Pending',
                count: state.pendingOrders.length,
                isSelected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
                isDestructive: state.pendingOrders.isNotEmpty,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

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
          child: state.isLoading && orders.isEmpty
              ? const Center(child: FProgress())
              : orders.isEmpty
                  ? _EmptyState(isPending: _selectedTab == 1)
                  : RefreshIndicator(
                      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _OrderTile(
                            order: order,
                            onConfirm: order.status == OrderStatus.submitted
                                ? () => _confirmOrder(order.id)
                                : null,
                            onCancel: order.status == OrderStatus.submitted
                                ? () => _cancelOrder(context, order.id)
                                : null,
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

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: theme.typography.sm.copyWith(
                color: isSelected ? theme.colors.primary : theme.colors.mutedForeground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDestructive ? theme.colors.destructive : theme.colors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: theme.typography.xs.copyWith(
                    color: isDestructive ? Colors.white : theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isPending;

  const _EmptyState({required this.isPending});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.check_circle_outline : Icons.inbox,
            size: 48,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(height: 12),
          Text(
            isPending ? 'No pending orders' : 'No orders yet',
            style: theme.typography.base.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatefulWidget {
  final Order order;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _OrderTile({
    required this.order,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final dateFormat = DateFormat('MMM d, h:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
      child: Column(
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
                        Row(
                          children: [
                            Text(
                              'Order #${widget.order.id}',
                              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: widget.order.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.order.items.length} items • ${currencyFormat.format(widget.order.total)} • ${dateFormat.format(widget.order.date)}',
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

          // Expanded content
          if (_expanded) ...[
            // Items
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
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
                  )),

                  // Actions for pending orders
                  if (widget.onConfirm != null || widget.onCancel != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (widget.onCancel != null)
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: FButton(
                                style: FButtonStyle.outline(),
                                onPress: widget.onCancel,
                                child: const Text('Cancel'),
                              ),
                            ),
                          ),
                        if (widget.onConfirm != null && widget.onCancel != null)
                          const SizedBox(width: 8),
                        if (widget.onConfirm != null)
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: FButton(
                                onPress: widget.onConfirm,
                                child: const Text('Confirm'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    Color bgColor;
    Color textColor;

    switch (status) {
      case OrderStatus.submitted:
        bgColor = theme.colors.destructive.withValues(alpha: 0.1);
        textColor = theme.colors.destructive;
        break;
      case OrderStatus.confirmed:
        bgColor = theme.colors.primary.withValues(alpha: 0.1);
        textColor = theme.colors.primary;
        break;
      case OrderStatus.cancelled:
        bgColor = theme.colors.secondary;
        textColor = theme.colors.mutedForeground;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name,
        style: theme.typography.xs.copyWith(color: textColor),
      ),
    );
  }
}
