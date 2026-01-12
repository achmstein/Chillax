import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_detail_sheet.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late FTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = FTabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: const Text('Orders'),
          suffixes: [
            FHeaderAction(
              icon: const Icon(Icons.refresh),
              onPress: () {
                ref.read(ordersProvider.notifier).loadOrders();
              },
            ),
          ],
        ),
        const FDivider(),

        // Tabs
        Padding(
          padding: const EdgeInsets.all(16),
          child: FTabs(
            
            children: [
              FTabEntry(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('All Orders'),
                    if (state.orders.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      FBadge(style: FBadgeStyle.secondary(), 
                        child: Text(state.orders.length.toString()),
                      ),
                    ],
                  ],
                ),
                child: _buildOrdersList(context, state.orders, state.isLoading),
              ),
              FTabEntry(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pending'),
                    if (state.pendingOrders.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      FBadge(style: FBadgeStyle.destructive(), 
                        child: Text(state.pendingOrders.length.toString()),
                      ),
                    ],
                  ],
                ),
                child: _buildOrdersList(context, state.pendingOrders, state.isLoading),
              ),
            ],
          ),
        ),

        // Error
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FAlert(style: FAlertStyle.destructive(), 
              icon: const Icon(Icons.warning),
              title: const Text('Error'),
              subtitle: Text(state.error!),
            ),
          ),
      ],
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders, bool isLoading) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat.yMd().add_Hm();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    if (isLoading && orders.isEmpty) {
      return const Expanded(
        child: Center(child: FProgress()),
      );
    }

    if (orders.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text(
                'No orders found',
                style: theme.typography.lg.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order = orders[index];
          return FCard(
            child: FTappable(
              onPress: () => _showOrderDetail(context, order),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with order info
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Order #${order.id}',
                                    style: theme.typography.base.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  _buildStatusBadge(order.status),
                                  if (order.tableNumber != null)
                                    FBadge(style: FBadgeStyle.secondary(),
                                      child: Text('Table ${order.tableNumber}'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.items.length} items - ${currencyFormat.format(order.total)}',
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              Text(
                                dateFormat.format(order.date),
                                style: theme.typography.xs.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCompact && order.status != OrderStatus.submitted)
                          const Icon(Icons.chevron_right),
                      ],
                    ),
                    // Action buttons (full width on mobile)
                    if (order.status == OrderStatus.submitted) ...[
                      const SizedBox(height: 12),
                      if (isCompact)
                        Row(
                          children: [
                            Expanded(
                              child: FButton(
                                style: FButtonStyle.outline(),
                                child: const Text('Cancel'),
                                onPress: () => _cancelOrder(context, order.id),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FButton(
                                child: const Text('Confirm'),
                                onPress: () => _confirmOrder(order.id),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FButton(
                              style: FButtonStyle.outline(),
                              child: const Text('Cancel'),
                              onPress: () => _cancelOrder(context, order.id),
                            ),
                            const SizedBox(width: 8),
                            FButton(
                              child: const Text('Confirm'),
                              onPress: () => _confirmOrder(order.id),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.submitted:
        return FBadge(style: FBadgeStyle.destructive(), 
          child: Text('Pending'),
        );
      case OrderStatus.confirmed:
        return FBadge(
          child: Text('Confirmed'),
        );
      case OrderStatus.cancelled:
        return FBadge(style: FBadgeStyle.outline(), 
          child: const Text('Cancelled'),
        );
    }
  }

  void _showOrderDetail(BuildContext context, Order order) {
    showFSheet(
      context: context,
      side: FLayout.rtl,
      builder: (context) => OrderDetailSheet(order: order),
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    await ref.read(ordersProvider.notifier).confirmOrder(orderId);
  }

  Future<void> _cancelOrder(BuildContext context, int orderId) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Cancel Order?'),
        body: const Text('Are you sure you want to cancel this order?'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('No, Keep'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: const Text('Yes, Cancel'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(ordersProvider.notifier).cancelOrder(orderId);
    }
  }
}
