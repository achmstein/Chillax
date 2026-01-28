import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../services/room_service.dart';

/// Screen showing user's session history
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(mySessionsProvider);
    final colors = context.theme.colors;

    return FScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(FIcons.arrowLeft, size: 22),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Session History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Sessions list
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FIcons.circleAlert, size: 48, color: colors.mutedForeground),
                      const SizedBox(height: 16),
                      Text('Failed to load sessions', style: TextStyle(color: colors.foreground)),
                      const SizedBox(height: 16),
                      FButton(
                        onPress: () => ref.read(mySessionsProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (sessions) => sessions.isEmpty
                    ? _buildEmptyState(colors)
                    : RefreshIndicator(
                        color: colors.primary,
                        backgroundColor: colors.background,
                        onRefresh: () => ref.read(mySessionsProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sessions.length,
                          separatorBuilder: (context, _) => Divider(height: 1, color: context.theme.colors.border),
                          itemBuilder: (context, index) {
                            return SessionTile(session: sessions[index]);
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.gamepad2,
            size: 80,
            color: colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 18,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reserve a room to get started',
            style: TextStyle(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Session tile
class SessionTile extends StatefulWidget {
  final RoomSession session;

  const SessionTile({super.key, required this.session});

  @override
  State<SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<SessionTile> {
  late final bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.session.status == SessionStatus.active;
    if (_isActive) {
      _startTimer();
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {});
      return _isActive && mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final session = widget.session;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(FIcons.gamepad2, size: 20, color: colors.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.roomName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.foreground,
                  ),
                ),
              ),
              _buildStatusBadge(widget.session.status),
            ],
          ),
          const SizedBox(height: 8),

          // Times
          Row(
            children: [
              Icon(FIcons.calendar, size: 14, color: colors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(session.reservationTime),
                style: TextStyle(color: colors.mutedForeground, fontSize: 13),
              ),
            ],
          ),

          if (session.status == SessionStatus.active) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(FIcons.timer, size: 14, color: colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Duration: ${session.formattedDuration}',
                  style: TextStyle(color: colors.mutedForeground, fontSize: 13),
                ),
              ],
            ),
          ],

          if (session.totalCost != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(FIcons.poundSterling, size: 14, color: colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  session.totalCost!.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: colors.foreground),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status) {
    switch (status) {
      case SessionStatus.reserved:
        return FBadge(style: FBadgeStyle.secondary(), child: Text(status.label));
      case SessionStatus.active:
        return FBadge(style: FBadgeStyle.primary(), child: Text(status.label));
      case SessionStatus.completed:
        return FBadge(style: FBadgeStyle.outline(), child: Text(status.label));
      case SessionStatus.cancelled:
        return FBadge(style: FBadgeStyle.destructive(), child: Text(status.label));
    }
  }
}
