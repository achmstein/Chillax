import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/service_request.dart';
import '../providers/service_requests_provider.dart';

/// Extension to get localized labels for service request types
extension ServiceRequestTypeLocalization on ServiceRequestType {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ServiceRequestType.callWaiter:
        return l10n.callWaiter;
      case ServiceRequestType.controllerChange:
        return l10n.controllerChange;
      case ServiceRequestType.receiptToPay:
        return l10n.receiptToPay;
    }
  }
}

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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
            children: [
              AppText(l10n.requests, style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              if (state.pendingRequests.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppText(
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
        ),

        // List
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.requests.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: RefreshIndicator(
              color: theme.colors.primary,
              backgroundColor: theme.colors.background,
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
    final l10n = AppLocalizations.of(context)!;
    if (state.requests.isEmpty) {
      return ListView(
        children: [
          EmptyState(
            icon: Icons.check_circle_outline,
            title: l10n.allClear,
            subtitle: l10n.noPendingRequests,
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat('MMM d, h:mm a', locale.languageCode);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).viewPadding.bottom,
            ),
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
                      child: AppText(
                        request.requestType.localizedLabel(l10n),
                        style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildStatusIndicator(request.status, theme, l10n),
                  ],
                ),
                const SizedBox(height: 16),
                // Details
                _DetailRow(icon: Icons.videogame_asset_outlined, label: l10n.room, value: request.roomName.localized(context)),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.person_outline, label: l10n.customer, value: request.userName),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.access_time, label: l10n.time, value: dateFormat.format(request.createdAt.toLocal())),
                const SizedBox(height: 20),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: () {
                      Navigator.pop(context);
                      _handleTap(request);
                    },
                    child: AppText(
                      request.status == ServiceRequestStatus.pending
                          ? l10n.acknowledge
                          : l10n.markComplete,
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

  Widget _buildStatusIndicator(ServiceRequestStatus status, FThemeData theme, AppLocalizations l10n) {
    Color color;
    String label;

    switch (status) {
      case ServiceRequestStatus.pending:
        color = theme.colors.destructive;
        label = l10n.pendingStatus;
        break;
      case ServiceRequestStatus.acknowledged:
        color = Colors.orange;
        label = l10n.inProgress;
        break;
      case ServiceRequestStatus.completed:
        color = const Color(0xFF16A34A);
        label = l10n.done;
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
        AppText(
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
    final l10n = AppLocalizations.of(context)!;
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
    final timeAgo = _getTimeAgo(request.createdAt, l10n);

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
                          AppText(
                            request.requestType.localizedLabel(l10n),
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppText(
                            '•',
                            style: TextStyle(color: theme.colors.mutedForeground),
                          ),
                          const SizedBox(width: 8),
                          AppText(
                            request.roomName.localized(context),
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        '${request.userName} • $timeAgo',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action hint
                AppText(
                  isPending ? l10n.tap : isAcknowledged ? l10n.doneLabel : '',
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

  String _getTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());

    if (diff.inMinutes < 1) {
      return l10n.justNow;
    } else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.hoursAgo(diff.inHours);
    } else {
      return l10n.daysAgo(diff.inDays);
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
        AppText(
          '$label:',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(width: 8),
        AppText(
          value,
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
