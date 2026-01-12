import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../rooms/models/room.dart';
import '../../rooms/providers/rooms_provider.dart';
import '../providers/dashboard_provider.dart';

class ActiveSessionsWidget extends ConsumerStatefulWidget {
  final List<RoomSession> sessions;

  const ActiveSessionsWidget({super.key, required this.sessions});

  @override
  ConsumerState<ActiveSessionsWidget> createState() => _ActiveSessionsWidgetState();
}

class _ActiveSessionsWidgetState extends ConsumerState<ActiveSessionsWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every second for live timers
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

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
                      Icons.videogame_asset,
                      size: 20,
                      color: theme.colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Sessions',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.sessions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      FBadge(
                        child: Text(widget.sessions.length.toString()),
                      ),
                    ],
                  ],
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  child: const Icon(Icons.arrow_forward),
                  onPress: () => context.go('/rooms'),
                ),
              ],
            ),
          ),
          const FDivider(),
          if (widget.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 48,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active sessions',
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
              itemCount: widget.sessions.length,
              separatorBuilder: (_, __) => const FDivider(),
              itemBuilder: (context, index) {
                final session = widget.sessions[index];
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
                                  session.roomName,
                                  style: theme.typography.base.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                session.status == SessionStatus.active
                                    ? FBadge(
                                        child: Text(session.status.label),
                                      )
                                    : FBadge(style: FBadgeStyle.secondary(), 
                                        child: Text(session.status.label),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Timer display
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colors.secondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    session.formattedDuration,
                                    style: theme.typography.lg.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: theme.colors.secondaryForeground,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Live cost
                                Text(
                                  currencyFormat.format(session.liveCost),
                                  style: theme.typography.base.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      FButton(
                        style: FButtonStyle.destructive(),
                        child: const Text('End Session'),
                        onPress: () => _endSession(context, session.id),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _endSession(BuildContext context, int sessionId) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('End Session?'),
        body: const Text('Are you sure you want to end this session? The customer will be charged for the time used.'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('Cancel'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            child: const Text('End Session'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(roomsProvider.notifier).endSession(sessionId);
      ref.read(dashboardProvider.notifier).loadDashboard();
    }
  }
}
