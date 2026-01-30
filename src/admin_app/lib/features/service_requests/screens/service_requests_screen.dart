import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/ui_components.dart';
import '../models/service_request.dart';
import '../providers/service_requests_provider.dart';

class ServiceRequestsScreen extends ConsumerStatefulWidget {
  const ServiceRequestsScreen({super.key});

  @override
  ConsumerState<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends ConsumerState<ServiceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(serviceRequestsProvider.notifier).loadRequests();
    });

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/service-requests' && previous != '/service-requests' && previous != null) {
        ref.read(serviceRequestsProvider.notifier).loadRequests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceRequestsProvider);
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('Requests', style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              if (state.pendingRequests.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.pendingRequests.length}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.destructiveForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.requests.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: RefreshIndicator(
              onRefresh: () => ref.read(serviceRequestsProvider.notifier).loadRequests(),
              child: _buildRequestsList(context, state, theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    ServiceRequestsState state,
    FThemeData theme,
  ) {
    if (state.requests.isEmpty) {
      return ListView(
        children: const [
          EmptyState(
            icon: Icons.check_circle_outline,
            title: 'All clear',
            subtitle: 'No pending requests',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.requests.length,
      itemBuilder: (context, index) {
        final request = state.requests[index];
        return _RequestTile(
          request: request,
          onTap: () => _handleTap(request),
          onInfoTap: () => _showDetails(context, request),
        );
      },
    );
  }

  void _handleTap(ServiceRequest request) {
    if (request.status == ServiceRequestStatus.pending) {
      _acknowledgeRequest(request.id);
    } else if (request.status == ServiceRequestStatus.acknowledged) {
      _completeRequest(request.id);
    }
  }

  void _showDetails(BuildContext context, ServiceRequest request) {
    final theme = context.theme;
    final dateFormat = DateFormat('MMM d, h:mm a');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colors.mutedForeground,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Type and status
                Row(
                  children: [
                    _getTypeIcon(request.requestType, theme),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request.requestType.label,
                        style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildStatusIndicator(request.status, theme),
                  ],
                ),
                const SizedBox(height: 16),
                // Details
                _DetailRow(icon: Icons.meeting_room, label: 'Room', value: request.roomName),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.person_outline, label: 'Customer', value: request.userName),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.access_time, label: 'Time', value: dateFormat.format(request.createdAt.toLocal())),
                const SizedBox(height: 20),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: () {
                      Navigator.pop(context);
                      _handleTap(request);
                    },
                    child: Text(
                      request.status == ServiceRequestStatus.pending
                          ? 'Acknowledge'
                          : 'Mark Complete',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _acknowledgeRequest(int requestId) async {
    await ref.read(serviceRequestsProvider.notifier).acknowledgeRequest(requestId);
  }

  Future<void> _completeRequest(int requestId) async {
    await ref.read(serviceRequestsProvider.notifier).completeRequest(requestId);
  }

  Widget _getTypeIcon(ServiceRequestType type, FThemeData theme) {
    IconData icon;
    Color color;

    switch (type) {
      case ServiceRequestType.callWaiter:
        icon = Icons.person_pin;
        color = theme.colors.primary;
        break;
      case ServiceRequestType.controllerChange:
        icon = Icons.gamepad;
        color = const Color(0xFF9333EA);
        break;
      case ServiceRequestType.receiptToPay:
        icon = Icons.receipt_long;
        color = const Color(0xFF16A34A);
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusIndicator(ServiceRequestStatus status, FThemeData theme) {
    Color color;
    String label;

    switch (status) {
      case ServiceRequestStatus.pending:
        color = theme.colors.destructive;
        label = 'Pending';
        break;
      case ServiceRequestStatus.acknowledged:
        color = Colors.orange;
        label = 'In Progress';
        break;
      case ServiceRequestStatus.completed:
        color = const Color(0xFF16A34A);
        label = 'Done';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.typography.sm.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Compact request tile with tap-to-action
class _RequestTile extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const _RequestTile({
    required this.request,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isPending = request.status == ServiceRequestStatus.pending;
    final isAcknowledged = request.status == ServiceRequestStatus.acknowledged;

    // Background tint based on status
    Color? bgColor;
    if (isPending) {
      bgColor = theme.colors.destructive.withValues(alpha: 0.05);
    } else if (isAcknowledged) {
      bgColor = Colors.orange.withValues(alpha: 0.05);
    }

    // Time ago
    final timeAgo = _getTimeAgo(request.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bgColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPending
                    ? theme.colors.destructive.withValues(alpha: 0.2)
                    : isAcknowledged
                        ? Colors.orange.withValues(alpha: 0.2)
                        : theme.colors.border,
              ),
            ),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isPending
                        ? theme.colors.destructive
                        : isAcknowledged
                            ? Colors.orange
                            : const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),

                // Type icon
                _buildTypeIcon(theme),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            request.requestType.label,
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: theme.colors.mutedForeground),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request.roomName,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.userName} • $timeAgo',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action hint
                Text(
                  isPending ? 'TAP' : isAcknowledged ? 'DONE' : '',
                  style: theme.typography.xs.copyWith(
                    color: isPending
                        ? theme.colors.destructive
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),

                // Info button
                GestureDetector(
                  onTap: onInfoTap,
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(FThemeData theme) {
    IconData icon;
    Color color;

    switch (request.requestType) {
      case ServiceRequestType.callWaiter:
        icon = Icons.person_pin;
        color = theme.colors.primary;
        break;
      case ServiceRequestType.controllerChange:
        icon = Icons.gamepad;
        color = const Color(0xFF9333EA);
        break;
      case ServiceRequestType.receiptToPay:
        icon = Icons.receipt_long;
        color = const Color(0xFF16A34A);
        break;
    }

    return Icon(icon, color: color, size: 20);
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colors.mutedForeground),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
