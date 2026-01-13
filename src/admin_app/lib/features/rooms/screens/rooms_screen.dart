import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../models/room.dart';
import '../providers/rooms_provider.dart';
import '../widgets/room_form_dialog.dart';

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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Error
                    if (state.error != null) ...[
                      FAlert(
                        style: FAlertStyle.destructive(),
                        icon: const Icon(Icons.warning),
                        title: const Text('Error'),
                        subtitle: Text(state.error!),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Room status section
                    Text(
                      'Room Status',
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Responsive room grid/list
                    _RoomStatusSection(
                      rooms: state.rooms,
                      activeSessions: state.activeSessions,
                      onReserve: _reserveRoom,
                      onStartSession: _startSession,
                      onEndSession: (id) => _endSession(context, id),
                      onEdit: (room) => _showRoomForm(context, room: room),
                      onDelete: (room) => _deleteRoom(context, room),
                    ),

                    const SizedBox(height: 24),

                    // Active sessions section
                    Text(
                      'Active Sessions',
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (state.activeSessions.isEmpty)
                      _EmptySessionsState()
                    else
                      ...state.activeSessions.map((session) {
                        return _SessionTile(
                          session: session,
                          currencyFormat: currencyFormat,
                          onStart: () => _startSession(session.id),
                          onEnd: () => _endSession(context, session.id),
                          onCancel: () => _cancelSession(context, session.id),
                        );
                      }),
                  ],
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

/// Responsive room status section - list on mobile, grid on tablet
class _RoomStatusSection extends StatelessWidget {
  final List<Room> rooms;
  final List<RoomSession> activeSessions;
  final Function(int) onReserve;
  final Function(int) onStartSession;
  final Function(int) onEndSession;
  final Function(Room) onEdit;
  final Function(Room) onDelete;

  const _RoomStatusSection({
    required this.rooms,
    required this.activeSessions,
    required this.onReserve,
    required this.onStartSession,
    required this.onEndSession,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return _EmptyRoomsState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        if (isTablet) {
          // Grid layout for tablet
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 900 ? 3 : 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final session = activeSessions
                  .where((s) => s.roomId == room.id)
                  .firstOrNull;
              return _RoomCard(
                room: room,
                session: session,
                onReserve: () => onReserve(room.id),
                onStartSession:
                    session != null ? () => onStartSession(session.id) : null,
                onEndSession:
                    session != null ? () => onEndSession(session.id) : null,
                onEdit: () => onEdit(room),
                onDelete: session == null ? () => onDelete(room) : null,
              );
            },
          );
        }

        // List layout for mobile
        return Column(
          children: rooms.map((room) {
            final session =
                activeSessions.where((s) => s.roomId == room.id).firstOrNull;
            return _RoomTile(
              room: room,
              session: session,
              onReserve: () => onReserve(room.id),
              onStartSession:
                  session != null ? () => onStartSession(session.id) : null,
              onEndSession:
                  session != null ? () => onEndSession(session.id) : null,
              onEdit: () => onEdit(room),
              onDelete: session == null ? () => onDelete(room) : null,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Mobile room tile - compact list item
class _RoomTile extends StatefulWidget {
  final Room room;
  final RoomSession? session;
  final VoidCallback onReserve;
  final VoidCallback? onStartSession;
  final VoidCallback? onEndSession;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _RoomTile({
    required this.room,
    this.session,
    required this.onReserve,
    this.onStartSession,
    this.onEndSession,
    required this.onEdit,
    this.onDelete,
  });

  @override
  State<_RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<_RoomTile> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupTimer();
  }

  @override
  void didUpdateWidget(_RoomTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _timer?.cancel();
    _setupTimer();
  }

  void _setupTimer() {
    if (widget.session?.status == SessionStatus.active) {
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isActive = widget.session?.status == SessionStatus.active;
    final isReserved = widget.session?.status == SessionStatus.reserved;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colors.destructive.withValues(alpha: 0.05)
            : theme.colors.background,
        border: Border.all(
          color: isActive
              ? theme.colors.destructive.withValues(alpha: 0.3)
              : theme.colors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getStatusColor(theme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.videogame_asset,
                    color: _getStatusColor(theme),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Room info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.room.name,
                              style: theme.typography.sm.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _buildStatusBadge(theme),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(widget.room.hourlyRate)}/hr',
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') widget.onEdit();
                    if (value == 'delete') widget.onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (widget.onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete,
                                size: 18, color: theme.colors.destructive),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style:
                                    TextStyle(color: theme.colors.destructive)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Active session info
          if (isActive && widget.session != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  // Timer
                  Text(
                    widget.session!.formattedDuration,
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currencyFormat.format(widget.session!.liveCost),
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    child: FButton(
                      style: FButtonStyle.destructive(),
                      onPress: widget.onEndSession,
                      child: const Text('End'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reserved - start button
          if (isReserved && widget.session != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Text(
                    'Reserved - ready to start',
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    child: FButton(
                      onPress: widget.onStartSession,
                      child: const Text('Start'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Available - reserve button
          if (!isActive &&
              !isReserved &&
              widget.room.status == RoomStatus.available) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    child: FButton(
                      style: FButtonStyle.outline(),
                      onPress: widget.onReserve,
                      child: const Text('Reserve'),
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

  Widget _buildStatusBadge(FThemeData theme) {
    if (widget.session?.status == SessionStatus.active) {
      return FBadge(
        style: FBadgeStyle.destructive(),
        child: const Text('In Use'),
      );
    }
    if (widget.session?.status == SessionStatus.reserved) {
      return FBadge(
        style: FBadgeStyle.secondary(),
        child: const Text('Reserved'),
      );
    }

    switch (widget.room.status) {
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

  Color _getStatusColor(FThemeData theme) {
    if (widget.session?.status == SessionStatus.active) {
      return theme.colors.destructive;
    }
    if (widget.session?.status == SessionStatus.reserved) {
      return Colors.orange;
    }

    switch (widget.room.status) {
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

/// Tablet room card - for grid layout
class _RoomCard extends StatefulWidget {
  final Room room;
  final RoomSession? session;
  final VoidCallback onReserve;
  final VoidCallback? onStartSession;
  final VoidCallback? onEndSession;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _RoomCard({
    required this.room,
    this.session,
    required this.onReserve,
    this.onStartSession,
    this.onEndSession,
    required this.onEdit,
    this.onDelete,
  });

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupTimer();
  }

  @override
  void didUpdateWidget(_RoomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _timer?.cancel();
    _setupTimer();
  }

  void _setupTimer() {
    if (widget.session?.status == SessionStatus.active) {
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isActive = widget.session?.status == SessionStatus.active;
    final isReserved = widget.session?.status == SessionStatus.reserved;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? theme.colors.destructive.withValues(alpha: 0.05)
            : theme.colors.background,
        border: Border.all(
          color: isActive
              ? theme.colors.destructive.withValues(alpha: 0.3)
              : theme.colors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(theme).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.videogame_asset,
                  color: _getStatusColor(theme),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.name,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${currencyFormat.format(widget.room.hourlyRate)}/hr',
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(theme),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.colors.mutedForeground,
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') widget.onEdit();
                  if (value == 'delete') widget.onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (widget.onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: 18, color: theme.colors.destructive),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style:
                                  TextStyle(color: theme.colors.destructive)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Active session
          if (isActive && widget.session != null) ...[
            Row(
              children: [
                Text(
                  widget.session!.formattedDuration,
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(widget.session!.liveCost),
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: FButton(
                style: FButtonStyle.destructive(),
                onPress: widget.onEndSession,
                child: const Text('End Session'),
              ),
            ),
          ],

          // Reserved
          if (isReserved && widget.session != null) ...[
            Text(
              'Reserved - ready to start',
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: FButton(
                onPress: widget.onStartSession,
                child: const Text('Start Session'),
              ),
            ),
          ],

          // Available
          if (!isActive &&
              !isReserved &&
              widget.room.status == RoomStatus.available) ...[
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: FButton(
                style: FButtonStyle.outline(),
                onPress: widget.onReserve,
                child: const Text('Reserve'),
              ),
            ),
          ],

          // Maintenance
          if (widget.room.status == RoomStatus.maintenance) ...[
            const Spacer(),
            Text(
              'Under maintenance',
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FThemeData theme) {
    if (widget.session?.status == SessionStatus.active) {
      return FBadge(
        style: FBadgeStyle.destructive(),
        child: const Text('In Use'),
      );
    }
    if (widget.session?.status == SessionStatus.reserved) {
      return FBadge(
        style: FBadgeStyle.secondary(),
        child: const Text('Reserved'),
      );
    }

    switch (widget.room.status) {
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

  Color _getStatusColor(FThemeData theme) {
    if (widget.session?.status == SessionStatus.active) {
      return theme.colors.destructive;
    }
    if (widget.session?.status == SessionStatus.reserved) {
      return Colors.orange;
    }

    switch (widget.room.status) {
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

/// Session list tile for mobile
class _SessionTile extends StatefulWidget {
  final RoomSession session;
  final NumberFormat currencyFormat;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  const _SessionTile({
    required this.session,
    required this.currencyFormat,
    required this.onStart,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
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
    final isActive = session.status == SessionStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  session.roomName,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              isActive
                  ? FBadge(child: Text(session.status.label))
                  : FBadge(
                      style: FBadgeStyle.secondary(),
                      child: Text(session.status.label),
                    ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _StatItem(
                label: 'Duration',
                value: session.formattedDuration,
                isMono: true,
              ),
              _StatItem(
                label: 'Cost',
                value: widget.currencyFormat.format(session.liveCost),
                valueColor: theme.colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          if (session.status == SessionStatus.reserved)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: FButton(
                      style: FButtonStyle.outline(),
                      onPress: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: FButton(
                      onPress: widget.onStart,
                      child: const Text('Start'),
                    ),
                  ),
                ),
              ],
            )
          else if (session.status == SessionStatus.active)
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FButton(
                style: FButtonStyle.destructive(),
                onPress: widget.onEnd,
                child: const Text('End Session'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.isMono = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          Text(
            value,
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: isMono ? 'monospace' : null,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoomsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.videogame_asset_off,
              size: 40,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              'No rooms configured',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySessionsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 40,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              'No active sessions',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
