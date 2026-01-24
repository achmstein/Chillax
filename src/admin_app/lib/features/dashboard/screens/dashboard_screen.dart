import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      children: [
        // Header
        _Header(onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard()),

        // Content
        Expanded(
          child: state.isLoading && state.stats.pendingOrdersCount == 0
              ? const Center(child: FProgress())
              : RefreshIndicator(
                  onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Error
                      if (state.error != null) ...[
                        Container(
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
                        const SizedBox(height: 16),
                      ],

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
                          _QuickStat(
                            label: 'Revenue',
                            value: currencyFormat.format(state.stats.todayRevenue),
                            color: Colors.green,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Pending orders section
                      _SectionHeader(
                        title: 'Pending Orders',
                        count: state.stats.pendingOrders.length,
                        onViewAll: () => context.go('/orders'),
                      ),
                      const SizedBox(height: 8),
                      if (state.stats.pendingOrders.isEmpty)
                        _EmptyState(
                          icon: Icons.check_circle_outline,
                          message: 'No pending orders',
                        )
                      else
                        ...state.stats.pendingOrders.take(5).map((order) =>
                          _PendingOrderTile(
                            order: order,
                            onConfirm: () => _confirmOrder(order.id),
                            onCancel: () => _cancelOrder(context, order.id),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Active sessions section
                      _SectionHeader(
                        title: 'Active Sessions',
                        count: state.stats.activeSessions.length,
                        onViewAll: () => context.go('/rooms'),
                      ),
                      const SizedBox(height: 8),
                      if (state.stats.activeSessions.isEmpty)
                        _EmptyState(
                          icon: Icons.videogame_asset_outlined,
                          message: 'No active sessions',
                        )
                      else
                        ...state.stats.activeSessions.take(5).map((session) =>
                          _SessionTile(session: session),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    // Call confirm via orders provider
  }

  Future<void> _cancelOrder(BuildContext context, int orderId) async {
    // Call cancel via orders provider
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;

  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Dashboard',
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRefresh,
            child: Icon(Icons.refresh, size: 20, color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        Text(
          title,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.typography.xs.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all',
            style: theme.typography.sm.copyWith(color: theme.colors.primary),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colors.mutedForeground),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final timeFormat = DateFormat.Hm();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} items • ${currencyFormat.format(order.total)} • ${timeFormat.format(order.date)}',
                      style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              if (order.tableNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colors.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Table ${order.tableNumber}',
                    style: theme.typography.xs,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: FButton(
                    style: FButtonStyle.outline(),
                    onPress: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: FButton(
                    onPress: onConfirm,
                    child: const Text('Confirm'),
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
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
                  session.roomName,
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
