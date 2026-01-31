import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/ui_components.dart';
import '../providers/dashboard_provider.dart';
import '../../orders/models/order.dart';
import '../../rooms/models/room.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _notifier = ref.read(dashboardProvider.notifier);
      _notifier?.loadDashboard();
      _notifier?.startAutoRefresh();
    });

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/dashboard' && previous != '/dashboard' && previous != null) {
        ref.read(dashboardProvider.notifier).loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _notifier?.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = context.theme;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('Dashboard', style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.stats.pendingOrdersCount == 0,
            shimmer: const ShimmerLoadingList(),
            child: RefreshIndicator(
                  onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
                  child: ListView(
                    padding: kScreenPadding,
                    children: [
                      // Quick stats row
                      Row(
                        children: [
                          _QuickStat(
                            label: 'Pending',
                            value: '${state.stats.pendingOrdersCount}',
                            color: state.stats.pendingOrdersCount > 0
                                ? theme.colors.destructive
                                : theme.colors.mutedForeground,
                          ),
                          _QuickStat(
                            label: 'Active',
                            value: '${state.stats.activeSessionsCount}',
                            color: state.stats.activeSessionsCount > 0
                                ? theme.colors.primary
                                : theme.colors.mutedForeground,
                          ),
                          _QuickStat(
                            label: 'Available',
                            value: '${state.stats.availableRoomsCount}',
                            color: theme.colors.mutedForeground,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Pending orders section
                      SectionHeader(
                        title: 'Pending Orders',
                        count: state.stats.pendingOrders.length,
                        actionText: 'View all',
                        onAction: () => context.go('/orders'),
                      ),
                      const SizedBox(height: 8),
                      if (state.stats.pendingOrders.isEmpty)
                        const EmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'No pending orders',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.stats.pendingOrders.take(5).length,
                          separatorBuilder: (_, __) => const FDivider(),
                          itemBuilder: (context, index) {
                            final order = state.stats.pendingOrders[index];
                            return _PendingOrderTile(
                              order: order,
                              onConfirm: () => _confirmOrder(order.id),
                              onCancel: () => _cancelOrder(context, order.id),
                            );
                          },
                        ),

                      const SizedBox(height: 24),

                      // Active sessions section
                      SectionHeader(
                        title: 'Active Sessions',
                        count: state.stats.activeSessions.length,
                        actionText: 'View all',
                        onAction: () => context.go('/rooms'),
                      ),
                      const SizedBox(height: 8),
                      if (state.stats.activeSessions.isEmpty)
                        const EmptyState(
                          icon: Icons.videogame_asset_outlined,
                          title: 'No active sessions',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.stats.activeSessions.take(5).length,
                          separatorBuilder: (_, __) => const FDivider(),
                          itemBuilder: (context, index) {
                            final session = state.stats.activeSessions[index];
                            return _SessionTile(session: session);
                          },
                        ),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    final api = ref.read(ordersApiProvider);
    try {
      await api.put('confirm', data: {'orderNumber': orderId});
      ref.read(dashboardProvider.notifier).loadDashboard();
    } catch (e) {
      debugPrint('Failed to confirm order: $e');
    }
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
            child: const Text('Keep'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: const Text('Cancel'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(ordersApiProvider);
      try {
        await api.put('cancel', data: {'orderNumber': orderId});
        ref.read(dashboardProvider.notifier).loadDashboard();
      } catch (e) {
        debugPrint('Failed to cancel order: $e');
      }
    }
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

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
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingOrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PendingOrderTile({
    required this.order,
    required this.onConfirm,
    required this.onCancel,
  });

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Left: Room/Order indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: order.roomName != null
                  ? Text(
                      order.roomName!.replaceAll('Room ', '').replaceAll('Table ', ''),
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                    )
                  : Text(
                      '#${order.id}',
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
                      child: Text(
                        order.userName ?? 'Order #${order.id}',
                        style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _getTimeAgo(order.date),
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(order.total),
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
                onTap: onCancel,
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
                onTap: onConfirm,
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
    );
  }
}

class _SessionTile extends StatelessWidget {
  final RoomSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: session.status == SessionStatus.active
                  ? theme.colors.primary.withValues(alpha: 0.1)
                  : theme.colors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.videogame_asset,
              size: 18,
              color: session.status == SessionStatus.active
                  ? theme.colors.primary
                  : theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.roomName.en,
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${session.formattedDuration} • ${currencyFormat.format(session.liveCost)}',
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: session.status == SessionStatus.active
                  ? theme.colors.primary.withValues(alpha: 0.1)
                  : theme.colors.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              session.status.label,
              style: theme.typography.xs.copyWith(
                color: session.status == SessionStatus.active
                    ? theme.colors.primary
                    : theme.colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
