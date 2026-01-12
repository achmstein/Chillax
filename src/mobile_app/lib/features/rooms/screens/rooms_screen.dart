import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/services/notification_service.dart';
import '../models/room.dart';
import '../services/room_service.dart';

/// Rooms screen for viewing and reserving PlayStation rooms
class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Column(
      children: [
        // Header
        FHeader(
          title: const Text('Rooms', style: TextStyle(fontSize: 18)),
        ),

        // Rooms list
        Expanded(
          child: roomsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FIcons.circleAlert, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('Failed to load rooms'),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () => ref.refresh(roomsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (rooms) {
              final allUnavailable = rooms.isNotEmpty &&
                  rooms.every((r) => r.status != RoomStatus.available);

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(roomsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: rooms.length + (allUnavailable ? 1 : 0),
                  separatorBuilder: (_, index) {
                    if (allUnavailable && index == 0) return const SizedBox.shrink();
                    return Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppTheme.textMuted.withOpacity(0.2),
                    );
                  },
                  itemBuilder: (context, index) {
                    if (allUnavailable && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: NotifyMeBanner(),
                      );
                    }
                    final roomIndex = allUnavailable ? index - 1 : index;
                    return RoomListItem(room: rooms[roomIndex]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Banner prompting user to subscribe for room availability notifications
class NotifyMeBanner extends ConsumerWidget {
  const NotifyMeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(roomAvailabilitySubscriptionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FIcons.bell, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'All rooms are currently busy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Get notified when a room becomes available',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          subscriptionAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => FButton(
              onPress: () => ref.refresh(roomAvailabilitySubscriptionProvider),
              child: const Text('Retry'),
            ),
            data: (isSubscribed) => isSubscribed
                ? Row(
                    children: [
                      Icon(FIcons.check, size: 16, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will be notified when a room is available',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: () async {
                          final success = await ref
                              .read(roomAvailabilitySubscriptionProvider.notifier)
                              .unsubscribe();
                          if (success && context.mounted) {
                            showFToast(
                              context: context,
                              title: const Text('Unsubscribed from notifications'),
                              icon: Icon(FIcons.check, color: AppTheme.textMuted),
                            );
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: () async {
                        final success = await ref
                            .read(roomAvailabilitySubscriptionProvider.notifier)
                            .subscribe();
                        if (context.mounted) {
                          if (success) {
                            showFToast(
                              context: context,
                              title: const Text('You will be notified!'),
                              icon: Icon(FIcons.bell, color: AppTheme.successColor),
                            );
                          } else {
                            showFToast(
                              context: context,
                              title: const Text('Failed to subscribe'),
                              icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
                            );
                          }
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FIcons.bell, size: 16),
                          SizedBox(width: 8),
                          Text('Notify Me'),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Room list item - minimal design like menu items
class RoomListItem extends ConsumerWidget {
  final Room room;

  const RoomListItem({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = room.status == RoomStatus.available;
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: isAvailable ? () => _showReservationDialog(context, ref) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gamepad icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isAvailable
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FIcons.gamepad2,
                size: 28,
                color: isAvailable ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 12),

            // Room info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (room.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      room.description!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '£${room.hourlyRate.toStringAsFixed(0)}/hr',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${room.status.label}',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action
            if (isAvailable)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  FIcons.calendarPlus,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (room.status) {
      case RoomStatus.available:
        return AppTheme.successColor;
      case RoomStatus.occupied:
        return AppTheme.errorColor;
      case RoomStatus.reserved:
        return AppTheme.warningColor;
      case RoomStatus.maintenance:
        return AppTheme.textMuted;
    }
  }

  void _showReservationDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReservationSheet(room: room),
    );
  }
}

/// Reservation bottom sheet
class ReservationSheet extends ConsumerStatefulWidget {
  final Room room;

  const ReservationSheet({super.key, required this.room});

  @override
  ConsumerState<ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends ConsumerState<ReservationSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reserve ${widget.room.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(FIcons.x, size: 24, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '£${widget.room.hourlyRate.toStringAsFixed(0)}/hour',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // Date picker
              const Text(
                'Select Date',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(FIcons.calendar, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time picker
              const Text(
                'Select Time',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(FIcons.clock, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reserve button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReserve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Reservation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReserve() async {
    setState(() => _isLoading = true);

    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await ref
        .read(reservationProvider.notifier)
        .reserveRoom(widget.room.id, selectedDateTime);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ref.refresh(roomsProvider);
      ref.refresh(mySessionsProvider);
      showFToast(
        context: context,
        title: const Text('Room reserved successfully!'),
        icon: Icon(FIcons.check, color: AppTheme.successColor),
      );
    } else if (mounted) {
      showFToast(
        context: context,
        title: const Text('Failed to reserve room'),
        icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
      );
    }
  }
}

