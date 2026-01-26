import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order.dart';
import '../services/order_service.dart';

/// Orders history screen - minimalistic
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Column(
      children: [
        // Header
        FHeader(
          title: const Text('Orders', style: TextStyle(fontSize: 18)),
        ),

        // Body
        Expanded(
          child: ordersAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FIcons.circleAlert, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('Failed to load orders: $error'),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () => ref.refresh(ordersProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (orders) => orders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async => ref.refresh(ordersProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const FDivider(),
                      itemBuilder: (context, index) {
                        return OrderTile(order: orders[index]);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.receipt,
            size: 80,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order tile - minimalistic expandable
class OrderTile extends StatefulWidget {
  final Order order;

  const OrderTile({super.key, required this.order});

  @override
  State<OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<OrderTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - tappable to expand
        FTappable(
          onPress: () => setState(() => _expanded = !_expanded),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(widget.order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            dateFormat.format(widget.order.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (widget.order.tableNumber != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• Table ${widget.order.tableNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '£${widget.order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded ? FIcons.chevronUp : FIcons.chevronDown,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        if (_expanded) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order items
                if (widget.order.items.isNotEmpty) ...[
                  ...widget.order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              '${item.units}x ',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            Expanded(child: Text(item.productName)),
                            Text(
                              '£${item.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )),
                ],

                // Customer note
                if (widget.order.customerNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${widget.order.customerNote}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.submitted:
        return FBadge(style: FBadgeStyle.secondary(), child: Text(status.label));
      case OrderStatus.confirmed:
        return FBadge(style: FBadgeStyle.primary(), child: Text(status.label));
      case OrderStatus.cancelled:
        return FBadge(style: FBadgeStyle.destructive(), child: Text(status.label));
    }
  }
}
