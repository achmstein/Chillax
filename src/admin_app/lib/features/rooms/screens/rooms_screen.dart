import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/ui_components.dart';
import '../models/room.dart';
import '../providers/rooms_provider.dart';
import '../widgets/access_code_display.dart';
import '../widgets/room_form_sheet.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Rooms',
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.rooms.length}',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _showRoomForm(context),
                tooltip: 'Add room',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () => ref.read(roomsProvider.notifier).loadRooms(),
                tooltip: 'Refresh',
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

        // Content
        Expanded(
          child: state.isLoading && state.rooms.isEmpty
              ? const ShimmerLoadingList()
              : _RoomStatusSection(
                  rooms: state.rooms,
                  activeSessions: state.activeSessions,
                  onReserve: _reserveRoom,
                  onStartWalkIn: _startWalkIn,
                  onStartSession: _startSession,
                  onEndSession: (id) => _endSession(context, id),
                  onEdit: (room) => _showRoomForm(context, room: room),
                  onDelete: (room) => _deleteRoom(context, room),
                  onTapRoom: (room) => _showRoomDetail(context, room),
                ),
        ),
      ],
    );
  }

  void _showRoomForm(BuildContext context, {Room? room}) {
    showFSheet(
      context: context,
      side: FLayout.rtl,
      builder: (context) => RoomFormSheet(room: room),
    );
  }

  void _showRoomDetail(BuildContext context, Room room) {
    context.go('/rooms/${room.id}');
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

}

/// Responsive room status section - list on mobile, grid on tablet
class _RoomStatusSection extends StatelessWidget {
  final List<Room> rooms;
  final List<RoomSession> activeSessions;
  final Function(int) onReserve;
  final Function(int) onStartWalkIn;
  final Function(int) onStartSession;
  final Function(int) onEndSession;
  final Function(Room) onEdit;
  final Function(Room) onDelete;
  final Function(Room) onTapRoom;

  const _RoomStatusSection({
    required this.rooms,
    required this.activeSessions,
    required this.onReserve,
    required this.onStartWalkIn,
    required this.onStartSession,
    required this.onEndSession,
    required this.onEdit,
    required this.onDelete,
    required this.onTapRoom,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const EmptyState(
        icon: Icons.videogame_asset_off,
        title: 'No rooms configured',
        subtitle: 'Add a room to get started',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        if (isTablet) {
          // Grid layout for tablet
          return GridView.builder(
            padding: kScreenPadding,
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
                onStartWalkIn: () => onStartWalkIn(room.id),
                onStartSession:
                    session != null ? () => onStartSession(session.id) : null,
                onEndSession:
                    session != null ? () => onEndSession(session.id) : null,
                onEdit: () => onEdit(room),
                onDelete: session == null ? () => onDelete(room) : null,
                onTap: () => onTapRoom(room),
              );
            },
          );
        }

        // List layout for mobile - simple rows with separators
        return ListView.separated(
          padding: kScreenPadding,
          itemCount: rooms.length,
          separatorBuilder: (_, __) => const FDivider(),
          itemBuilder: (context, index) {
            final room = rooms[index];
            final session =
                activeSessions.where((s) => s.roomId == room.id).firstOrNull;
            return _RoomTile(
              room: room,
              session: session,
              onReserve: () => onReserve(room.id),
              onStartWalkIn: () => onStartWalkIn(room.id),
              onStartSession:
                  session != null ? () => onStartSession(session.id) : null,
              onEndSession:
                  session != null ? () => onEndSession(session.id) : null,
              onTap: () => onTapRoom(room),
              isLast: index == rooms.length - 1,
            );
          },
        );
      },
    );
  }
}

/// Mobile room tile - simple row design without borders
class _RoomTile extends StatefulWidget {
  final Room room;
  final RoomSession? session;
  final VoidCallback onReserve;
  final VoidCallback onStartWalkIn;
  final VoidCallback? onStartSession;
  final VoidCallback? onEndSession;
  final VoidCallback onTap;
  final bool isLast;

  const _RoomTile({
    required this.room,
    this.session,
    required this.onReserve,
    required this.onStartWalkIn,
    this.onStartSession,
    this.onEndSession,
    required this.onTap,
    this.isLast = false,
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

  void _showQuickActions(BuildContext context, Offset position) {
    final theme = context.theme;
    final isAvailable = widget.room.status == RoomStatus.available &&
        widget.session == null;

    if (!isAvailable) return;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.schedule, size: 18, color: theme.colors.foreground),
              const SizedBox(width: 8),
              const Text('Reserve'),
            ],
          ),
          onTap: widget.onReserve,
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18, color: theme.colors.primary),
              const SizedBox(width: 8),
              Text('Start Now', style: TextStyle(color: theme.colors.primary)),
            ],
          ),
          onTap: widget.onStartWalkIn,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isActive = widget.session?.status == SessionStatus.active;
    final isReserved = widget.session?.status == SessionStatus.reserved;
    final isAvailable = widget.room.status == RoomStatus.available &&
        !isActive && !isReserved;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: isAvailable
          ? (details) => _showQuickActions(context, details.globalPosition)
          : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Status icon
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
                  Text(
                    widget.room.name,
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Show session info or price
                  if (isActive && widget.session != null)
                    Row(
                      children: [
                        Text(
                          widget.session!.formattedDuration,
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
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
                        if (widget.session!.accessCode != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.session!.accessCode!,
                              style: theme.typography.xs.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  else if (isReserved && widget.session != null)
                    Row(
                      children: [
                        Text(
                          'Ready to start',
                          style: theme.typography.sm.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                        if (widget.session!.accessCode != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.session!.accessCode!,
                              style: theme.typography.xs.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Text(
                      '${currencyFormat.format(widget.room.hourlyRate)}/hr',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),

            // Action button
            if (isActive)
              FButton(
                style: FButtonStyle.destructive(),
                onPress: widget.onEndSession,
                child: const Text('End'),
              )
            else if (isReserved)
              FButton(
                onPress: widget.onStartSession,
                child: const Text('Start'),
              )
            else if (isAvailable)
              FButton(
                style: FButtonStyle.outline(),
                onPress: widget.onReserve,
                child: const Text('Reserve'),
              )
            else
              Icon(
                Icons.chevron_right,
                color: theme.colors.mutedForeground,
              ),
          ],
        ),
      ),
    );
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
  final VoidCallback onStartWalkIn;
  final VoidCallback? onStartSession;
  final VoidCallback? onEndSession;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    this.session,
    required this.onReserve,
    required this.onStartWalkIn,
    this.onStartSession,
    this.onEndSession,
    required this.onEdit,
    this.onDelete,
    required this.onTap,
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
    final isAvailable = widget.room.status == RoomStatus.available &&
        !isActive && !isReserved;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
        padding: kScreenPadding,
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
              ],
            ),

            const Spacer(),

            // Active session
            if (isActive && widget.session != null) ...[
              // Access code
              if (widget.session!.accessCode != null) ...[
                AccessCodeDisplay(
                  code: widget.session!.accessCode!,
                  compact: true,
                ),
                const SizedBox(height: 8),
              ],
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
                child: FButton(
                  style: FButtonStyle.destructive(),
                  onPress: widget.onEndSession,
                  child: const Text('End Session'),
                ),
              ),
            ],

            // Reserved
            if (isReserved && widget.session != null) ...[
              // Access code
              if (widget.session!.accessCode != null) ...[
                AccessCodeDisplay(
                  code: widget.session!.accessCode!,
                  compact: true,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Reserved - ready to start',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: widget.onStartSession,
                  child: const Text('Start Session'),
                ),
              ),
            ],

            // Available - show both Reserve and Start Now buttons
            if (isAvailable) ...[
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
                      onPress: widget.onReserve,
                      child: const Text('Reserve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(
                      onPress: widget.onStartWalkIn,
                      child: const Text('Start Now'),
                    ),
                  ),
                ],
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
      ),
    );
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
