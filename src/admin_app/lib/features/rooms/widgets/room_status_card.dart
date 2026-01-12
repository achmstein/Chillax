import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';

class RoomStatusCard extends StatefulWidget {
  final Room room;
  final RoomSession? activeSession;
  final VoidCallback onReserve;
  final VoidCallback? onStartSession;
  final VoidCallback? onEndSession;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoomStatusCard({
    super.key,
    required this.room,
    this.activeSession,
    required this.onReserve,
    this.onStartSession,
    this.onEndSession,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<RoomStatusCard> createState() => _RoomStatusCardState();
}

class _RoomStatusCardState extends State<RoomStatusCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.activeSession?.status == SessionStatus.active) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(RoomStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeSession?.status == SessionStatus.active &&
        oldWidget.activeSession?.status != SessionStatus.active) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (widget.activeSession?.status != SessionStatus.active) {
      _timer?.cancel();
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

    return SizedBox(
      width: 280,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.videogame_asset,
                          size: 24,
                          color: _getStatusColor(theme),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.room.name,
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusBadge(),
                      if (widget.onEdit != null || widget.onDelete != null) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: theme.colors.mutedForeground,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32),
                          onSelected: (value) {
                            if (value == 'edit') {
                              widget.onEdit?.call();
                            } else if (value == 'delete') {
                              widget.onDelete?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            if (widget.onEdit != null)
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
                                    Icon(Icons.delete, size: 18,
                                      color: theme.colors.destructive),
                                    const SizedBox(width: 8),
                                    Text('Delete',
                                      style: TextStyle(
                                        color: theme.colors.destructive)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Rate
              Text(
                '${currencyFormat.format(widget.room.hourlyRate)} / hour',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),

              // Session info or action
              if (widget.activeSession != null) ...[
                const SizedBox(height: 16),
                const FDivider(),
                const SizedBox(height: 16),

                if (widget.activeSession!.status == SessionStatus.active) ...[
                  // Timer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.activeSession!.formattedDuration,
                          style: theme.typography.xl2.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(widget.activeSession!.liveCost),
                          style: theme.typography.lg.copyWith(
                            color: theme.colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      style: FButtonStyle.destructive(),
                      child: const Text('End Session'),
                      onPress: widget.onEndSession,
                    ),
                  ),
                ] else if (widget.activeSession!.status == SessionStatus.reserved) ...[
                  // Reserved - show start button
                  Text(
                    'Reserved - waiting to start',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      child: const Text('Start Session'),
                      onPress: widget.onStartSession,
                    ),
                  ),
                ],
              ] else if (widget.room.status == RoomStatus.available) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    style: FButtonStyle.outline(),
                    child: const Text('Reserve'),
                    onPress: widget.onReserve,
                  ),
                ),
              ] else if (widget.room.status == RoomStatus.maintenance) ...[
                const SizedBox(height: 16),
                Text(
                  'Under maintenance',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (widget.activeSession?.status == SessionStatus.active) {
      return FBadge(style: FBadgeStyle.destructive(), 
        child: Text('In Use'),
      );
    }
    if (widget.activeSession?.status == SessionStatus.reserved) {
      return FBadge(style: FBadgeStyle.secondary(), 
        child: Text('Reserved'),
      );
    }

    switch (widget.room.status) {
      case RoomStatus.available:
        return FBadge(
          child: Text('Available'),
        );
      case RoomStatus.occupied:
        return FBadge(style: FBadgeStyle.destructive(), 
          child: Text('Occupied'),
        );
      case RoomStatus.reserved:
        return FBadge(style: FBadgeStyle.secondary(), 
          child: Text('Reserved'),
        );
      case RoomStatus.maintenance:
        return FBadge(style: FBadgeStyle.outline(), 
          child: const Text('Maintenance'),
        );
    }
  }

  Color _getStatusColor(FThemeData theme) {
    if (widget.activeSession?.status == SessionStatus.active) {
      return theme.colors.destructive;
    }
    if (widget.activeSession?.status == SessionStatus.reserved) {
      return theme.colors.secondary;
    }

    switch (widget.room.status) {
      case RoomStatus.available:
        return theme.colors.primary;
      case RoomStatus.occupied:
        return theme.colors.destructive;
      case RoomStatus.reserved:
        return theme.colors.secondary;
      case RoomStatus.maintenance:
        return theme.colors.mutedForeground;
    }
  }
}
