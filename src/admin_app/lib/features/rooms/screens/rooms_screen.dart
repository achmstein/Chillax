import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../models/room.dart';
import '../providers/rooms_provider.dart';
import '../widgets/room_form_dialog.dart';
import '../widgets/room_status_card.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(roomsProvider.notifier).loadRooms();
    });

    // Auto-refresh for live timers
    _timer = Timer.periodic(AppConfig.roomsRefreshInterval, (_) {
      ref.read(roomsProvider.notifier).loadRooms();
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: const Text('PS Rooms'),
          suffixes: [
            FHeaderAction(
              icon: const Icon(Icons.add),
              onPress: () => _showRoomForm(context),
            ),
            FHeaderAction(
              icon: const Icon(Icons.refresh),
              onPress: () {
                ref.read(roomsProvider.notifier).loadRooms();
              },
            ),
          ],
        ),
        const FDivider(),

        // Content
        Expanded(
          child: state.isLoading && state.rooms.isEmpty
              ? const Center(child: FProgress())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error
                      if (state.error != null) ...[
                        FAlert(style: FAlertStyle.destructive(), 
                          icon: const Icon(Icons.warning),
                          title: const Text('Error'),
                          subtitle: Text(state.error!),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Room status grid
                      Text(
                        'Room Status',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: state.rooms.map((room) {
                          final session = state.activeSessions
                              .where((s) => s.roomId == room.id)
                              .firstOrNull;
                          return RoomStatusCard(
                            room: room,
                            activeSession: session,
                            onReserve: () => _reserveRoom(room.id),
                            onStartSession: session != null
                                ? () => _startSession(session.id)
                                : null,
                            onEndSession: session != null
                                ? () => _endSession(context, session.id)
                                : null,
                            onEdit: () => _showRoomForm(context, room: room),
                            onDelete: session == null
                                ? () => _deleteRoom(context, room)
                                : null,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Active sessions table
                      Text(
                        'Active Sessions',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (state.activeSessions.isEmpty)
                        FCard(
                          child: Padding(
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
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 600;
                            if (isCompact) {
                              // Card layout for mobile
                              return Column(
                                children: state.activeSessions.map((session) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _SessionCard(
                                      session: session,
                                      currencyFormat: currencyFormat,
                                      onStart: () => _startSession(session.id),
                                      onEnd: () => _endSession(context, session.id),
                                      onCancel: () => _cancelSession(context, session.id),
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                            // Table layout for tablet
                            return FCard(
                              child: Column(
                                children: [
                                  // Table header
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.colors.secondary,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Room',
                                            style: theme.typography.sm.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Status',
                                            style: theme.typography.sm.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Duration',
                                            style: theme.typography.sm.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Cost',
                                            style: theme.typography.sm.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 3,
                                          child: SizedBox(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Table rows
                                  ...state.activeSessions.map((session) {
                                    return _SessionRow(
                                      session: session,
                                      currencyFormat: currencyFormat,
                                      onStart: () => _startSession(session.id),
                                      onEnd: () => _endSession(context, session.id),
                                      onCancel: () => _cancelSession(context, session.id),
                                    );
                                  }),
                                ],
                              ),
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

  void _showRoomForm(BuildContext context, {Room? room}) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => RoomFormDialog(room: room),
    );
  }

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Delete Room?'),
        body: Text('Are you sure you want to delete "${room.name}"? This action cannot be undone.'),
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
    }
  }

  Future<void> _reserveRoom(int roomId) async {
    await ref.read(roomsProvider.notifier).reserveRoom(roomId);
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
    }
  }

  Future<void> _cancelSession(BuildContext context, int sessionId) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Cancel Reservation?'),
        body: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('No, Keep'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: const Text('Yes, Cancel'),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(roomsProvider.notifier).cancelSession(sessionId);
    }
  }
}

class _SessionRow extends StatefulWidget {
  final RoomSession session;
  final NumberFormat currencyFormat;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  const _SessionRow({
    required this.session,
    required this.currencyFormat,
    required this.onStart,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.session.status == SessionStatus.active) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final session = widget.session;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              session.roomName,
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: session.status == SessionStatus.active
                ? FBadge(
                    child: Text(session.status.label),
                  )
                : FBadge(style: FBadgeStyle.secondary(), 
                    child: Text(session.status.label),
                  ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              session.formattedDuration,
              style: theme.typography.sm.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              widget.currencyFormat.format(session.liveCost),
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (session.status == SessionStatus.reserved) ...[
                  FButton(
                    style: FButtonStyle.outline(),
                    child: const Text('Cancel'),
                    onPress: widget.onCancel,
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    child: const Text('Start'),
                    onPress: widget.onStart,
                  ),
                ] else if (session.status == SessionStatus.active)
                  FButton(
                    style: FButtonStyle.destructive(),
                    child: const Text('End Session'),
                    onPress: widget.onEnd,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile-friendly session card widget
class _SessionCard extends StatefulWidget {
  final RoomSession session;
  final NumberFormat currencyFormat;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  const _SessionCard({
    required this.session,
    required this.currencyFormat,
    required this.onStart,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.session.status == SessionStatus.active) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final session = widget.session;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with room name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.roomName,
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                session.status == SessionStatus.active
                    ? FBadge(child: Text(session.status.label))
                    : FBadge(
                        style: FBadgeStyle.secondary(),
                        child: Text(session.status.label),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            // Duration and cost
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        session.formattedDuration,
                        style: theme.typography.sm.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cost',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        widget.currencyFormat.format(session.liveCost),
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            if (session.status == SessionStatus.reserved)
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
                      child: const Text('Cancel'),
                      onPress: widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(
                      child: const Text('Start'),
                      onPress: widget.onStart,
                    ),
                  ),
                ],
              )
            else if (session.status == SessionStatus.active)
              SizedBox(
                width: double.infinity,
                child: FButton(
                  style: FButtonStyle.destructive(),
                  child: const Text('End Session'),
                  onPress: widget.onEnd,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
