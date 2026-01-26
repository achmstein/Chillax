import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/ui_components.dart';
import '../models/room.dart';
import '../providers/rooms_provider.dart';
import '../widgets/access_code_display.dart';
import '../widgets/room_form_sheet.dart';

/// Full page screen showing room details and session history
class RoomDetailScreen extends ConsumerStatefulWidget {
  final int roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(roomsProvider.notifier).loadRooms();
      ref.read(roomsProvider.notifier).loadSessionHistory(widget.roomId);
    });

    // Auto-refresh for live timers
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Don't call ref.read in dispose - it can cause issues with defunct elements
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomsProvider);
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final room = state.rooms.where((r) => r.id == widget.roomId).firstOrNull;
    final session = state.activeSessions
        .where((s) => s.roomId == widget.roomId)
        .firstOrNull;

    if (room == null) {
      return Column(
        children: [
          _buildHeader(context, theme, null),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    final isActive = session?.status == SessionStatus.active;
    final isReserved = session?.status == SessionStatus.reserved;
    final isAvailable =
        room.status == RoomStatus.available && !isActive && !isReserved;

    return Column(
      children: [
        _buildHeader(context, theme, room),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: kScreenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room info card
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _getStatusColor(theme, room, session)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.videogame_asset,
                        color: _getStatusColor(theme, room, session),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currencyFormat.format(room.hourlyRate)}/hr',
                            style: theme.typography.xl.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (room.description != null &&
                              room.description!.isNotEmpty)
                            Text(
                              room.description!,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(theme, room, session),
                  ],
                ),

                const SizedBox(height: 24),

                // Current session info
                if (isActive && session != null) ...[
                  _ActiveSessionCard(
                    session: session,
                    onEndSession: () => _endSession(context, session.id),
                  ),
                  const SizedBox(height: 24),
                ],

                if (isReserved && session != null) ...[
                  _ReservedSessionCard(
                    session: session,
                    onStartSession: () => _startSession(session.id),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons for available rooms
                if (isAvailable) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => _reserveRoom(room.id),
                          child: const Text('Reserve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FButton(
                          onPress: () => _startWalkIn(room.id),
                          child: const Text('Start Now'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Management buttons
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.outline(),
                        onPress: () => _showEditSheet(context, room),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ),
                    if (session == null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.destructive(),
                          onPress: () => _deleteRoom(context, room),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, size: 18),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),
                const FDivider(),
                const SizedBox(height: 16),

                // Session history
                Text(
                  'Session History',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (state.isLoadingHistory)
                  const ShimmerLoadingList(itemCount: 3)
                else if (state.sessionHistory == null ||
                    state.sessionHistory!.isEmpty)
                  const EmptyState(
                    icon: Icons.history,
                    title: 'No session history',
                    subtitle: 'Previous sessions will appear here',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.sessionHistory!.length,
                    separatorBuilder: (_, __) => const FDivider(),
                    itemBuilder: (context, index) {
                      final historySession = state.sessionHistory![index];
                      return _SessionHistoryTile(session: historySession);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, FThemeData theme, Room? room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/rooms'),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Text(
            room?.name ?? 'Room Details',
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () {
              ref.read(roomsProvider.notifier).loadRooms();
              ref.read(roomsProvider.notifier).loadSessionHistory(widget.roomId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, Room room) {
    showFSheet(
      context: context,
      side: FLayout.rtl,
      builder: (context) => RoomFormSheet(room: room),
    );
  }

  Future<void> _reserveRoom(int roomId) async {
    await ref.read(roomsProvider.notifier).reserveRoom(roomId);
  }

  Future<void> _startWalkIn(int roomId) async {
    await ref.read(roomsProvider.notifier).startWalkInSession(roomId);
  }

  Future<void> _startSession(int sessionId) async {
    await ref.read(roomsProvider.notifier).startSession(sessionId);
  }

  Future<void> _endSession(BuildContext context, int sessionId) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('End Session?'),
        body: const Text(
            'Are you sure you want to end this session? The customer will be charged for the time used.'),
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
    }
  }

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Delete Room?'),
        body: Text(
            'Are you sure you want to delete "${room.name}"? This action cannot be undone.'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('Cancel'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: const Text('Delete'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(roomsProvider.notifier).deleteRoom(room.id);
      if (mounted) {
        context.go('/rooms');
      }
    }
  }

  Widget _buildStatusBadge(
      FThemeData theme, Room room, RoomSession? session) {
    if (session?.status == SessionStatus.active) {
      return FBadge(
        style: FBadgeStyle.destructive(),
        child: const Text('In Use'),
      );
    }
    if (session?.status == SessionStatus.reserved) {
      return FBadge(
        style: FBadgeStyle.secondary(),
        child: const Text('Reserved'),
      );
    }

    switch (room.status) {
      case RoomStatus.available:
        return FBadge(child: const Text('Available'));
      case RoomStatus.occupied:
        return FBadge(
            style: FBadgeStyle.destructive(), child: const Text('Occupied'));
      case RoomStatus.reserved:
        return FBadge(
            style: FBadgeStyle.secondary(), child: const Text('Reserved'));
      case RoomStatus.maintenance:
        return FBadge(
            style: FBadgeStyle.outline(), child: const Text('Maintenance'));
    }
  }

  Color _getStatusColor(FThemeData theme, Room room, RoomSession? session) {
    if (session?.status == SessionStatus.active) {
      return theme.colors.destructive;
    }
    if (session?.status == SessionStatus.reserved) {
      return Colors.orange;
    }

    switch (room.status) {
      case RoomStatus.available:
        return theme.colors.primary;
      case RoomStatus.occupied:
        return theme.colors.destructive;
      case RoomStatus.reserved:
        return Colors.orange;
      case RoomStatus.maintenance:
        return theme.colors.mutedForeground;
    }
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final RoomSession session;
  final VoidCallback? onEndSession;

  const _ActiveSessionCard({
    required this.session,
    this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.destructive.withValues(alpha: 0.05),
        border: Border.all(
          color: theme.colors.destructive.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                size: 20,
                color: theme.colors.destructive,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Session',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Access code
          if (session.accessCode != null) ...[
            AccessCodeDisplay(code: session.accessCode!, compact: true),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Text(
                session.formattedDuration,
                style: theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currencyFormat.format(session.liveCost),
                style: theme.typography.lg.copyWith(
                  color: theme.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (onEndSession != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FButton(
                style: FButtonStyle.destructive(),
                onPress: onEndSession,
                child: const Text('End Session'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReservedSessionCard extends StatelessWidget {
  final RoomSession session;
  final VoidCallback? onStartSession;

  const _ReservedSessionCard({
    required this.session,
    this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 20,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Reserved - Ready to Start',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          // Access code
          if (session.accessCode != null) ...[
            const SizedBox(height: 12),
            AccessCodeDisplay(code: session.accessCode!, compact: true),
          ],

          if (onStartSession != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: onStartSession,
                child: const Text('Start Session'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionHistoryTile extends StatelessWidget {
  final RoomSession session;

  const _SessionHistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.history,
              size: 20,
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.startTime != null
                      ? dateFormat.format(session.startTime!.toLocal())
                      : 'Unknown',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.formattedDuration,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(session.totalCost ?? session.liveCost),
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
