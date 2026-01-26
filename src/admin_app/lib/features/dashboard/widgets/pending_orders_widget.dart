import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../orders/models/order.dart';
import '../../orders/providers/orders_provider.dart';
import '../providers/dashboard_provider.dart';

class PendingOrdersWidget extends ConsumerWidget {
  final List<Order> orders;

  const PendingOrdersWidget({super.key, required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final timeFormat = DateFormat.Hm();

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: 20,
                      color: theme.colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Orders',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (orders.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      FBadge(style: FBadgeStyle.destructive(), 
                        child: Text(orders.length.toString()),
                      ),
                    ],
                  ],
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  child: const Icon(Icons.arrow_forward),
                  onPress: () => context.go('/orders'),
                ),
              ],
            ),
          ),
          const FDivider(),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending orders',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length > 5 ? 5 : orders.length,
              separatorBuilder: (_, _) => const FDivider(),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Order #${order.id}',
                                  style: theme.typography.base.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (order.tableNumber != null) ...[
                                  const SizedBox(width: 8),
                                  FBadge(style: FBadgeStyle.secondary(), 
                                    child: Text('Table ${order.tableNumber}'),
                                  ),
                                ],
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
                              timeFormat.format(order.date),
                              style: theme.typography.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FButton(
                            style: FButtonStyle.outline(),
                            child: const Text('Cancel'),
                            onPress: () => _cancelOrder(context, ref, order.id),
                          ),
                          const SizedBox(width: 8),
                          FButton(
                            child: const Text('Confirm'),
                            onPress: () => _confirmOrder(context, ref, order.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          if (orders.length > 5) ...[
            const FDivider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: FButton(
                  style: FButtonStyle.ghost(),
                  child: Text('View all ${orders.length} orders'),
                  onPress: () => context.go('/orders'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref, int orderId) async {
    await ref.read(ordersProvider.notifier).confirmOrder(orderId);
    ref.read(dashboardProvider.notifier).loadDashboard();
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, int orderId) async {
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
      ref.read(dashboardProvider.notifier).loadDashboard();
    }
  }
}
