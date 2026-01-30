import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../providers/rooms_provider.dart';
import '../widgets/room_form_sheet.dart';

/// Room detail screen - Split view: Now (top) + History (bottom)
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
    final state = ref.watch(roomsProvider);
    final theme = context.theme;

    final room = state.rooms.where((r) => r.id == widget.roomId).firstOrNull;
    final session = state.activeSessions
        .where((s) => s.roomId == widget.roomId)
        .firstOrNull;

    if (room == null) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme, null, null),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    final isActive = session?.status == SessionStatus.active;
    final isReserved = session?.status == SessionStatus.reserved;
    final isAvailable = room.status == RoomStatus.available && !isActive && !isReserved;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, theme, room, session),

            // TOP HALF: Current State
            _CurrentStateSection(
              room: room,
              session: session,
              isActive: isActive,
              isReserved: isReserved,
              isAvailable: isAvailable,
              onReserve: () => _reserveRoom(room.id),
              onWalkIn: () => _startWalkIn(room.id),
              onStartSession: session != null ? () => _startSession(session.id) : null,
              onEndSession: session != null ? () => _endSession(context, session.id) : null,
              onCancelReservation: session != null ? () => _cancelReservation(context, session.id) : null,
            ),

            // BOTTOM HALF: History
            Expanded(
              child: _HistorySection(
                sessions: state.sessionHistory ?? [],
                isLoading: state.isLoadingHistory,
                hasMore: state.hasMoreHistory,
                onLoadMore: () => ref.read(roomsProvider.notifier).loadSessionHistory(widget.roomId, loadMore: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FThemeData theme, Room? room, RoomSession? session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/rooms'),
          ),
          const Spacer(),
          if (room != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditSheet(context, room),
              tooltip: 'Edit',
            ),
            if (session == null)
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: theme.colors.destructive),
                onPressed: () => _deleteRoom(context, room),
                tooltip: 'Delete',
              ),
          ],
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
        body: const Text('The customer will be charged for the time used.'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('Cancel'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            child: const Text('End'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(roomsProvider.notifier).endSession(sessionId);
      // Reload history to show the completed session
      ref.read(roomsProvider.notifier).loadSessionHistory(widget.roomId);
    }
  }

  Future<void> _cancelReservation(BuildContext context, int sessionId) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Cancel Reservation?'),
        body: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('No'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: const Text('Cancel Reservation'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(roomsProvider.notifier).cancelSession(sessionId);
      // Reload history to show the cancelled session
      ref.read(roomsProvider.notifier).loadSessionHistory(widget.roomId);
    }
  }

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Delete Room?'),
        body: Text('Delete "${room.name}"? This cannot be undone.'),
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
      if (context.mounted) {
        context.go('/rooms');
      }
    }
  }
}

/// Top section: Current state (Now)
class _CurrentStateSection extends StatelessWidget {
  final Room room;
  final RoomSession? session;
  final bool isActive;
  final bool isReserved;
  final bool isAvailable;
  final VoidCallback onReserve;
  final VoidCallback onWalkIn;
  final VoidCallback? onStartSession;
  final VoidCallback? onEndSession;
  final VoidCallback? onCancelReservation;

  const _CurrentStateSection({
    required this.room,
    required this.session,
    required this.isActive,
    required this.isReserved,
    required this.isAvailable,
    required this.onReserve,
    required this.onWalkIn,
    this.onStartSession,
    this.onEndSession,
    this.onCancelReservation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '£');

    // Get status color
    Color statusColor;
    if (isActive) {
      statusColor = theme.colors.destructive;
    } else if (isReserved) {
      statusColor = Colors.orange;
    } else if (isAvailable) {
      statusColor = Colors.green;
    } else {
      statusColor = theme.colors.mutedForeground;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room name + status indicator
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  room.name,
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${currencyFormat.format(room.hourlyRate)}/hr',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Active Session: Show timer prominently
          if (isActive && session != null) ...[
            // Big timer
            Center(
              child: Column(
                children: [
                  Text(
                    session!.formattedDuration,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                      height: 1,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(session!.liveCost),
                    style: theme.typography.xl.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Session info row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (session!.userName != null) ...[
                  Icon(Icons.person_outline, size: 16, color: theme.colors.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    session!.userName!,
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                  ),
                ],
                if (session!.userName != null && session!.accessCode != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('•', style: TextStyle(color: theme.colors.mutedForeground)),
                  ),
                if (session!.accessCode != null) ...[
                  Icon(Icons.key_outlined, size: 16, color: theme.colors.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    session!.accessCode!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // End button
            Center(
              child: FButton(
                style: FButtonStyle.destructive(),
                onPress: onEndSession,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, size: 18),
                    SizedBox(width: 8),
                    Text('End Session'),
                  ],
                ),
              ),
            ),
          ],

          // Reserved: Show waiting state with countdown
          if (isReserved && session != null) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule, size: 32, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to Start',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (session!.userName != null)
                    Text(
                      session!.userName!,
                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                    ),
                  if (session!.accessCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${session!.accessCode!}',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  // Countdown timer display
                  if (session!.expiresAt != null) ...[
                    const SizedBox(height: 16),
                    _ExpirationCountdown(session: session!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FButton(
                  style: FButtonStyle.outline(),
                  onPress: onCancelReservation,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 8),
                      Text('Cancel'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FButton(
                  onPress: onStartSession,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, size: 18),
                      SizedBox(width: 8),
                      Text('Start Session'),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Available: Show actions
          if (isAvailable) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 32, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Available',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (room.description != null && room.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      room.description!,
                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FButton(
                  style: FButtonStyle.outline(),
                  onPress: onReserve,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Reserve'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FButton(
                  onPress: onWalkIn,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, size: 18),
                      SizedBox(width: 8),
                      Text('Walk-in'),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Maintenance or other unavailable states
          if (!isActive && !isReserved && !isAvailable) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.build_outlined, size: 32, color: theme.colors.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    room.status == RoomStatus.maintenance ? 'Under Maintenance' : 'Unavailable',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom section: History with pagination
class _HistorySection extends StatelessWidget {
  final List<RoomSession> sessions;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const _HistorySection({
    required this.sessions,
    required this.isLoading,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '£');
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'History',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // List
        Expanded(
          child: isLoading && sessions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No sessions yet',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sessions.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Load more button
                        if (index == sessions.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : GestureDetector(
                                      onTap: onLoadMore,
                                      child: Text(
                                        'Load more',
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.primary,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }

                        final session = sessions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              // Date & time
                              SizedBox(
                                width: 70,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.startTime != null
                                          ? dateFormat.format(session.startTime!.toLocal())
                                          : '-',
                                      style: theme.typography.sm.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      session.startTime != null
                                          ? timeFormat.format(session.startTime!.toLocal())
                                          : '',
                                      style: theme.typography.xs.copyWith(
                                        color: theme.colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // User
                              Expanded(
                                child: session.userName != null
                                    ? Text(
                                        session.userName!,
                                        style: theme.typography.sm,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text(
                                        'Walk-in',
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.mutedForeground,
                                        ),
                                      ),
                              ),

                              // Duration
                              Text(
                                session.formattedDuration,
                                style: theme.typography.sm.copyWith(
                                  fontFamily: 'monospace',
                                  color: theme.colors.mutedForeground,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Cost
                              SizedBox(
                                width: 60,
                                child: Text(
                                  currencyFormat.format(session.totalCost ?? session.liveCost),
                                  style: theme.typography.sm.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// Countdown timer widget for reservation expiration
class _ExpirationCountdown extends StatelessWidget {
  final RoomSession session;

  const _ExpirationCountdown({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final remaining = session.timeUntilExpiration;

    if (remaining == null) return const SizedBox.shrink();

    // Determine urgency level
    final isExpired = remaining.inSeconds <= 0;
    final isUrgent = remaining.inMinutes < 5;

    Color bgColor;
    Color textColor;
    String message;

    if (isExpired) {
      bgColor = theme.colors.destructive.withValues(alpha: 0.15);
      textColor = theme.colors.destructive;
      message = 'Expired - Auto-cancelling...';
    } else if (isUrgent) {
      bgColor = theme.colors.destructive.withValues(alpha: 0.1);
      textColor = theme.colors.destructive;
      message = 'Auto-cancel in ${session.formattedCountdown}';
    } else {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange.shade700;
      message = 'Expires in ${session.formattedCountdown}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent || isExpired ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: theme.typography.sm.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
