import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/models/localized_text.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/models/customer.dart';
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
              onAddCustomer: session != null && (isActive || isReserved)
                  ? () => _showAddCustomerSheet(context, session)
                  : null,
              onRemoveMember: session != null && isActive
                  ? (customerId) => _removeMember(context, session.id, customerId)
                  : null,
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
      useRootNavigator: true,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.endSession),
        body: AppText(l10n.customerWillBeCharged),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            child: AppText(l10n.end),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.cancelReservationQuestion),
        body: AppText(l10n.cancelReservationConfirmation),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.no),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.cancelReservation),
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

  void _showAddCustomerSheet(BuildContext context, RoomSession session) {
    // Collect already-assigned customer IDs to filter them out
    final existingCustomerIds = <String>{};
    if (session.customerId != null) existingCustomerIds.add(session.customerId!);
    for (final member in session.members) {
      existingCustomerIds.add(member.customerId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) => _AssignCustomerSheet(
        excludeCustomerIds: existingCustomerIds,
        onCustomerSelected: (customer) async {
          Navigator.pop(sheetContext);
          final l10n = AppLocalizations.of(context)!;
          bool success;
          if (session.customerId == null) {
            // No owner yet - assign as owner
            success = await ref.read(roomsProvider.notifier).assignCustomerToSession(
              session.id,
              customer.id,
              customer.displayName,
            );
          } else {
            // Already has owner - add as member
            success = await ref.read(roomsProvider.notifier).addMemberToSession(
              session.id,
              customer.id,
              customer.displayName,
            );
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? l10n.customerAssigned : l10n.failedToAssignCustomer)),
            );
          }
        },
      ),
    );
  }

  Future<void> _removeMember(BuildContext context, int sessionId, String customerId) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref.read(roomsProvider.notifier).removeMemberFromSession(sessionId, customerId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? l10n.memberRemoved : l10n.failedToRemoveMember)),
      );
    }
  }

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.deleteRoom),
        body: AppText(l10n.deleteRoomConfirmation(room.name.localized(context))),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.delete),
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
  final VoidCallback? onAddCustomer;
  final ValueChanged<String>? onRemoveMember;

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
    this.onAddCustomer,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

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
                child: AppText(
                  room.name.localized(context),
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppText(
                l10n.hourlyRateFormat(room.hourlyRate.toStringAsFixed(0)),
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
                  AppText(
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Access code row
            if (session!.accessCode != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.key_outlined, size: 16, color: theme.colors.mutedForeground),
                  const SizedBox(width: 4),
                  AppText(
                    session!.accessCode!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Members list
            if (session!.members.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: session!.members.map((member) {
                    return Chip(
                      avatar: Icon(
                        member.isOwner ? Icons.star : Icons.person,
                        size: 16,
                        color: member.isOwner ? Colors.amber : theme.colors.mutedForeground,
                      ),
                      label: AppText(
                        member.customerName ?? member.customerId,
                        style: theme.typography.sm,
                      ),
                      deleteIcon: member.isOwner ? null : const Icon(Icons.close, size: 16),
                      onDeleted: member.isOwner || onRemoveMember == null
                          ? null
                          : () => onRemoveMember!(member.customerId),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (session!.userName != null) ...[
              // Fallback: show single user name if no members loaded
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 16, color: theme.colors.mutedForeground),
                  const SizedBox(width: 4),
                  AppText(
                    session!.userName!,
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Add Customer button (always available for active sessions)
            if (onAddCustomer != null) ...[
              Center(
                child: FButton(
                  style: FButtonStyle.outline(),
                  onPress: onAddCustomer,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_outlined, size: 18),
                      const SizedBox(width: 8),
                      AppText(l10n.addCustomer),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // End button
            Center(
              child: FButton(
                style: FButtonStyle.destructive(),
                onPress: onEndSession,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stop, size: 18),
                    const SizedBox(width: 8),
                    AppText(l10n.endSessionButton),
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
                  AppText(
                    l10n.readyToStart,
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (session!.members.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: session!.members.map((member) {
                        return Chip(
                          avatar: Icon(
                            member.isOwner ? Icons.star : Icons.person,
                            size: 16,
                            color: member.isOwner ? Colors.amber : theme.colors.mutedForeground,
                          ),
                          label: AppText(
                            member.customerName ?? member.customerId,
                            style: theme.typography.sm,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    )
                  else if (session!.userName != null)
                    Chip(
                      avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                      label: AppText(
                        session!.userName!,
                        style: theme.typography.sm,
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (session!.accessCode != null) ...[
                    const SizedBox(height: 4),
                    AppText(
                      l10n.codeLabel(session!.accessCode!),
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

            const SizedBox(height: 16),

            // Add Customer button for reserved sessions
            if (onAddCustomer != null) ...[
              Center(
                child: FButton(
                  style: FButtonStyle.outline(),
                  onPress: onAddCustomer,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_outlined, size: 18),
                      const SizedBox(width: 8),
                      AppText(l10n.addCustomer),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FButton(
                  style: FButtonStyle.outline(),
                  onPress: onCancelReservation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, size: 18),
                      const SizedBox(width: 8),
                      AppText(l10n.cancel),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FButton(
                  onPress: onStartSession,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scaleX: Directionality.of(context) == TextDirection.rtl ? -1 : 1,
                        child: const Icon(Icons.play_arrow, size: 18),
                      ),
                      const SizedBox(width: 8),
                      AppText(l10n.startSession),
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
                  AppText(
                    l10n.available,
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (room.description != null && room.description!.en.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    AppText(
                      room.description!.localized(context),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_outline, size: 18),
                      const SizedBox(width: 8),
                      AppText(l10n.reserve),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FButton(
                  onPress: onWalkIn,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scaleX: Directionality.of(context) == TextDirection.rtl ? -1 : 1,
                        child: const Icon(Icons.play_arrow, size: 18),
                      ),
                      const SizedBox(width: 8),
                      AppText(l10n.walkIn),
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
                  AppText(
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
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM d', locale.languageCode);
    final timeFormat = DateFormat('h:mm a', locale.languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: AppText(
            l10n.history,
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
                      child: AppText(
                        l10n.noSessionsYet,
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
                                      child: AppText(
                                        l10n.loadMore,
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
                                    AppText(
                                      session.startTime != null
                                          ? dateFormat.format(session.startTime!.toLocal())
                                          : '-',
                                      style: theme.typography.sm.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    AppText(
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
                                    ? AppText(
                                        session.userName!,
                                        style: theme.typography.sm,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : AppText(
                                        l10n.walkIn,
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.mutedForeground,
                                        ),
                                      ),
                              ),

                              // Rounded hours (for POS entry)
                              AppText(
                                session.roundedHours != null
                                    ? _formatRoundedHours(session.roundedHours!)
                                    : session.formattedDuration,
                                style: theme.typography.sm.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
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

/// Format rounded hours: show "3h" for whole, "3.25h" / "3.5h" / "3.75h" for fractions
String _formatRoundedHours(double hours) {
  if (hours % 1 == 0) return '${hours.toInt()}h';
  // Remove trailing zeros: 3.50 -> 3.5, 2.25 -> 2.25
  final str = hours.toStringAsFixed(2);
  final trimmed = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return '${trimmed}h';
}

/// Countdown timer widget for reservation expiration
class _ExpirationCountdown extends StatelessWidget {
  final RoomSession session;

  const _ExpirationCountdown({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
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
      message = l10n.expiredAutoCancelling;
    } else if (isUrgent) {
      bgColor = theme.colors.destructive.withValues(alpha: 0.1);
      textColor = theme.colors.destructive;
      message = l10n.autoCancelIn(session.formattedCountdown);
    } else {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange.shade700;
      message = l10n.expiresIn(session.formattedCountdown);
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
          AppText(
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

/// Bottom sheet for searching and assigning a customer to an active session
class _AssignCustomerSheet extends ConsumerStatefulWidget {
  final ValueChanged<Customer> onCustomerSelected;
  final Set<String> excludeCustomerIds;

  const _AssignCustomerSheet({
    required this.onCustomerSelected,
    this.excludeCustomerIds = const {},
  });

  @override
  ConsumerState<_AssignCustomerSheet> createState() => _AssignCustomerSheetState();
}

class _AssignCustomerSheetState extends ConsumerState<_AssignCustomerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Customer> _results = [];
  bool _isSearching = false;
  late final ApiClient _identityApi;

  @override
  void initState() {
    super.initState();
    _identityApi = ref.read(identityApiProvider);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final response = await _identityApi.get('/users', queryParameters: {
        'search': query,
        'max': 20,
      });
      final data = response.data as List<dynamic>;
      final users = data
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .where((c) => !widget.excludeCustomerIds.contains(c.id))
          .toList();
      if (mounted) {
        setState(() {
          _results = users;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colors.mutedForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        l10n.addCustomer,
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: theme.colors.mutedForeground),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FTextField(
                  control: FTextFieldControl.managed(controller: _searchController),
                  hint: l10n.searchCustomerByName,
                ),
              ),
              const SizedBox(height: 8),

              // Results
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_results.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final customer = _results[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colors.secondary,
                          child: AppText(
                            customer.initials,
                            style: theme.typography.xs.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        title: AppText(customer.displayName, style: theme.typography.sm),
                        subtitle: customer.email != null
                            ? AppText(customer.email!,
                                style: theme.typography.xs
                                    .copyWith(color: theme.colors.mutedForeground))
                            : null,
                        onTap: () => widget.onCustomerSelected(customer),
                      );
                    },
                  ),
                )
              else if (_searchController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppText(
                    l10n.noCustomersFound,
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                  ),
                ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
