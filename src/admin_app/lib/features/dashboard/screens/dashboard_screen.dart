import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/pending_orders_widget.dart';
import '../widgets/active_sessions_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data and start auto-refresh
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboard();
      ref.read(dashboardProvider.notifier).startAutoRefresh();
    });
  }

  @override
  void dispose() {
    ref.read(dashboardProvider.notifier).stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: const Text('Dashboard'),
          suffixes: [
            FHeaderAction(
              icon: const Icon(Icons.refresh),
              onPress: () {
                ref.read(dashboardProvider.notifier).loadDashboard();
              },
            ),
          ],
        ),
        const FDivider(),

        // Content
        Expanded(
          child: state.isLoading && state.stats.pendingOrdersCount == 0
              ? const Center(child: FProgress())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error alert
                      if (state.error != null) ...[
                        FAlert(style: FAlertStyle.destructive(), 
                          icon: const Icon(Icons.warning),
                          title: const Text('Error'),
                          subtitle: Text(state.error!),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Stats cards
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 250,
                            child: StatCard(
                              title: 'Pending Orders',
                              value: state.stats.pendingOrdersCount.toString(),
                              icon: Icons.shopping_cart,
                              iconColor: state.stats.pendingOrdersCount > 0
                                  ? theme.colors.destructive
                                  : null,
                              subtitle: 'Waiting to be confirmed',
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: StatCard(
                              title: 'Active Sessions',
                              value: state.stats.activeSessionsCount.toString(),
                              icon: Icons.videogame_asset,
                              iconColor: state.stats.activeSessionsCount > 0
                                  ? theme.colors.primary
                                  : null,
                              subtitle: 'PS rooms in use',
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: StatCard(
                              title: 'Available Rooms',
                              value: state.stats.availableRoomsCount.toString(),
                              icon: Icons.door_front_door,
                              subtitle: 'Ready for customers',
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: StatCard(
                              title: "Today's Revenue",
                              value: currencyFormat.format(state.stats.todayRevenue),
                              icon: Icons.attach_money,
                              iconColor: Colors.green,
                              subtitle: 'From confirmed orders',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Two-column layout for pending orders and active sessions
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: PendingOrdersWidget(
                                    orders: state.stats.pendingOrders,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: ActiveSessionsWidget(
                                    sessions: state.stats.activeSessions,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              PendingOrdersWidget(
                                orders: state.stats.pendingOrders,
                              ),
                              const SizedBox(height: 24),
                              ActiveSessionsWidget(
                                sessions: state.stats.activeSessions,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
