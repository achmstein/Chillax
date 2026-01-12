import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrderDetailSheet extends ConsumerWidget {
  final Order order;

  const OrderDetailSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat.yMd().add_Hm();

    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  child: const Icon(Icons.close),
                  onPress: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const FDivider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and info
                  Row(
                    children: [
                      _buildStatusBadge(order.status),
                      if (order.tableNumber != null) ...[
                        const SizedBox(width: 8),
                        FBadge(style: FBadgeStyle.secondary(), 
                          child: Text('Table ${order.tableNumber}'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date
                  _buildInfoRow(theme, 'Date', dateFormat.format(order.date)),

                  // Customer note
                  if (order.customerNote != null && order.customerNote!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Customer Note',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.message,
                              size: 16,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.customerNote!,
                                style: theme.typography.sm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Order items
                  Text(
                    'Items',
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => _buildOrderItem(theme, item, currencyFormat)),

                  const SizedBox(height: 16),
                  const FDivider(),
                  const SizedBox(height: 16),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(order.total),
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          if (order.status == OrderStatus.submitted) ...[
            const FDivider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
                      child: const Text('Cancel Order'),
                      onPress: () => _cancelOrder(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      child: const Text('Confirm Order'),
                      onPress: () => _confirmOrder(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _buildInfoRow(FThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: theme.typography.sm,
        ),
      ],
    );
  }

  Widget _buildOrderItem(FThemeData theme, OrderItem item, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.units}x',
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${format.format(item.unitPrice)} each',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            format.format(item.totalPrice),
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    await ref.read(ordersProvider.notifier).confirmOrder(order.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
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
      await ref.read(ordersProvider.notifier).cancelOrder(order.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
