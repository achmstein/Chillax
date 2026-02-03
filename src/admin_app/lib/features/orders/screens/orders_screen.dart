import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders();
    });

    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/orders' && previous != '/orders' && previous != null) {
        ref.read(ordersProvider.notifier).loadOrders();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(ordersProvider.notifier).loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AppText(l10n.orders, style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              if (state.orders.isNotEmpty) ...[
                const SizedBox(width: 8),
                AppText(
                  '${state.orders.length}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.destructive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.orders.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: RefreshIndicator(
              onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
              child: state.orders.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        EmptyState(
                          icon: Icons.check_circle_outline,
                          title: l10n.noPendingOrders,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.orders.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.colors.border,
                      ),
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
        ),
      ],
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    await ref.read(ordersProvider.notifier).confirmOrder(orderId);
  }

  Future<void> _cancelOrder(BuildContext context, int orderId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.cancelOrder),
        body: AppText(l10n.cancelOrderConfirmation),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.keep),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.cancel),
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
  bool _expanded = true; // Expanded by default for pending orders

  String _getTimeAgo(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final orderDetailsAsync = ref.watch(orderDetailsProvider(widget.order.id));

    // Get items count from details if loaded, otherwise show nothing
    final itemsCount = orderDetailsAsync.whenOrNull(data: (d) => d.items.length);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row
            Row(
              children: [
                // Left: Order indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: AppText(
                      '#${widget.order.id}',
                      style: theme.typography.xs.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              widget.order.userName ?? l10n.orderNumber(widget.order.id),
                              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.order.roomName != null) ...[
                            const SizedBox(width: 8),
                            FBadge(
                              style: FBadgeStyle.secondary(),
                              child: AppText(widget.order.roomName!.localized(context)),
                            ),
                          ],
                          const SizedBox(width: 8),
                          AppText(
                            _getTimeAgo(widget.order.date, l10n),
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        itemsCount != null
                            ? '${l10n.itemCount(itemsCount)} • ${l10n.priceFormat(widget.order.total.toStringAsFixed(0))}'
                            : l10n.priceFormat(widget.order.total.toStringAsFixed(0)),
                        style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onConfirm,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 18,
                          color: theme.colors.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Expanded details
            if (_expanded) _buildExpandedContent(theme, l10n, orderDetailsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(FThemeData theme, AppLocalizations l10n, AsyncValue<Order> orderDetailsAsync) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 56),
      child: orderDetailsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => AppText(
          l10n.failedToLoad,
          style: theme.typography.xs.copyWith(color: theme.colors.destructive),
        ),
        data: (orderDetails) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Items
            ...orderDetails.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText(
                        '${item.units}× ',
                        style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                      ),
                      Expanded(
                        child: AppText(
                          item.productName.localized(context),
                          style: theme.typography.sm,
                        ),
                      ),
                      AppText(
                        l10n.priceFormat(item.totalPrice.toStringAsFixed(0)),
                        style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                      ),
                    ],
                  ),
                  if (item.customizationsDescription != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: AppText(
                        item.customizationsDescription!.localized(context),
                        style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                      ),
                    ),
                  if (item.specialInstructions != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: AppText(
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

            // Customer note
            if (orderDetails.customerNote != null) ...[
              const SizedBox(height: 4),
              AppText(
                'Note: ${orderDetails.customerNote}',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
