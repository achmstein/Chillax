import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/room.dart';
import '../services/room_service.dart';

/// Rooms screen for viewing and reserving PlayStation rooms
class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PlayStation Rooms'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available Rooms'),
              Tab(text: 'My Sessions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RoomsTab(),
            MySessionsTab(),
          ],
        ),
      ),
    );
  }
}

/// Tab showing available rooms
class RoomsTab extends ConsumerWidget {
  const RoomsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Failed to load rooms: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(roomsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (rooms) => RefreshIndicator(
        onRefresh: () async => ref.refresh(roomsProvider),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            return RoomCard(room: rooms[index]);
          },
        ),
      ),
    );
  }
}

/// Room card widget
class RoomCard extends ConsumerWidget {
  final Room room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = room.status == RoomStatus.available;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isAvailable ? () => _showReservationDialog(context, ref) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: _getStatusColor(room.status),
              child: Text(
                room.status.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Room image/icon
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: Icon(
                  Icons.videogame_asset,
                  size: 48,
                  color: isAvailable ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            ),

            // Room info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${room.hourlyRate.toStringAsFixed(0)}/hour',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return AppTheme.successColor;
      case RoomStatus.occupied:
        return AppTheme.errorColor;
      case RoomStatus.reserved:
        return AppTheme.warningColor;
      case RoomStatus.maintenance:
        return Colors.grey;
    }
  }

  void _showReservationDialog(BuildContext context, WidgetRef ref) {
    DateTime selectedTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Reserve ${room.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate: \$${room.hourlyRate.toStringAsFixed(0)}/hour'),
                const SizedBox(height: 16),
                const Text('Reservation Time:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          DateFormat('MMM d').format(selectedTime),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedTime),
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = DateTime(
                                selectedTime.year,
                                selectedTime.month,
                                selectedTime.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(
                          DateFormat('h:mm a').format(selectedTime),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(reservationProvider.notifier)
                      .reserveRoom(room.id, selectedTime);

                  if (success) {
                    ref.refresh(roomsProvider);
                    ref.refresh(mySessionsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room reserved successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to reserve room'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Reserve'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tab showing user's sessions
class MySessionsTab extends ConsumerWidget {
  const MySessionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(mySessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Failed to load sessions: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(mySessionsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (sessions) => sessions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async => ref.refresh(mySessionsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  return SessionCard(session: sessions[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videogame_asset_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reserve a room to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Session card widget
class SessionCard extends StatelessWidget {
  final RoomSession session;

  const SessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.videogame_asset),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.roomName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusBadge(session.status),
              ],
            ),
            const SizedBox(height: 12),

            // Times
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(session.reservationTime),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),

            if (session.status == SessionStatus.active) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${session.formattedDuration}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            if (session.totalCost != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Total: \$${session.totalCost!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case SessionStatus.reserved:
        backgroundColor = AppTheme.warningColor.withOpacity(0.2);
        textColor = AppTheme.warningColor;
        break;
      case SessionStatus.active:
        backgroundColor = AppTheme.successColor.withOpacity(0.2);
        textColor = AppTheme.successColor;
        break;
      case SessionStatus.completed:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        break;
      case SessionStatus.cancelled:
        backgroundColor = AppTheme.errorColor.withOpacity(0.2);
        textColor = AppTheme.errorColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
