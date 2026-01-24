import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceRequestsProvider);
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: const Text('Service Requests'),
          suffixes: [
            FHeaderAction(
              icon: const Icon(Icons.refresh),
              onPress: () {
                ref.read(serviceRequestsProvider.notifier).loadRequests();
              },
            ),
          ],
        ),
        const FDivider(),

        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _StatChip(
                label: 'Pending',
                count: state.pendingRequests.length,
                color: theme.colors.destructive,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Acknowledged',
                count: state.acknowledgedRequests.length,
                color: theme.colors.primary,
              ),
            ],
          ),
        ),

        // Error
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FAlert(
              style: FAlertStyle.destructive(),
              icon: const Icon(Icons.warning),
              title: const Text('Error'),
              subtitle: Text(state.error!),
            ),
          ),

        // List
        Expanded(
          child: _buildRequestsList(context, state, theme),
        ),
      ],
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    ServiceRequestsState state,
    FThemeData theme,
  ) {
    final dateFormat = DateFormat.yMd().add_Hm();

    if (state.isLoading && state.requests.isEmpty) {
      return const Center(child: FProgress());
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: theme.typography.lg.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All service requests have been handled',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.requests.length,
      separatorBuilder: (_, __) => const FDivider(),
      itemBuilder: (context, index) {
        final request = state.requests[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _RequestTypeIcon(type: request.requestType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.requestType.label,
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.roomName,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 12),
              // Details
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.userName,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(request.createdAt.toLocal()),
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (request.status == ServiceRequestStatus.pending) ...[
                    FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => _acknowledgeRequest(request.id),
                      child: const Text('Acknowledge'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FButton(
                    onPress: () => _completeRequest(request.id),
                    child: const Text('Complete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pending:
        return FBadge(
          style: FBadgeStyle.destructive(),
          child: Text(status.label),
        );
      case ServiceRequestStatus.acknowledged:
        return FBadge(
          style: FBadgeStyle.secondary(),
          child: Text(status.label),
        );
      case ServiceRequestStatus.completed:
        return FBadge(
          child: Text(status.label),
        );
    }
  }

  Future<void> _acknowledgeRequest(int requestId) async {
    final success = await ref
        .read(serviceRequestsProvider.notifier)
        .acknowledgeRequest(requestId);

    if (mounted && success) {
      showFToast(
        context: context,
        title: const Text('Request acknowledged'),
      );
    }
  }

  Future<void> _completeRequest(int requestId) async {
    final success = await ref
        .read(serviceRequestsProvider.notifier)
        .completeRequest(requestId);

    if (mounted && success) {
      showFToast(
        context: context,
        title: const Text('Request completed'),
      );
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: theme.typography.xs.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.typography.sm.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTypeIcon extends StatelessWidget {
  final ServiceRequestType type;

  const _RequestTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    IconData icon;
    Color color;

    switch (type) {
      case ServiceRequestType.callWaiter:
        icon = Icons.person_pin;
        color = theme.colors.primary;
        break;
      case ServiceRequestType.controllerChange:
        icon = Icons.gamepad;
        color = theme.colors.secondary.computeLuminance() > 0.5
            ? const Color(0xFF9333EA) // purple-600
            : const Color(0xFFA855F7); // purple-500
        break;
      case ServiceRequestType.receiptToPay:
        icon = Icons.receipt_long;
        color = theme.colors.secondary.computeLuminance() > 0.5
            ? const Color(0xFF16A34A) // green-600
            : const Color(0xFF22C55E); // green-500
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
