import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/room.dart';
import '../services/room_service.dart';

/// Screen showing user's session history
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(mySessionsProvider);

    return Column(
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
                  Icon(FIcons.circleAlert, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Failed to load sessions'),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () => ref.refresh(mySessionsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (sessions) => sessions.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async => ref.refresh(mySessionsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const FDivider(),
                      itemBuilder: (context, index) {
                        return SessionTile(session: sessions[index]);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.gamepad2,
            size: 80,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reserve a room to get started',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Session tile
class SessionTile extends StatelessWidget {
  final RoomSession session;

  const SessionTile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(FIcons.gamepad2, size: 20),
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
          const SizedBox(height: 8),

          // Times
          Row(
            children: [
              Icon(FIcons.calendar, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(session.reservationTime),
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),

          if (session.status == SessionStatus.active) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(FIcons.timer, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Duration: ${session.formattedDuration}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],

          if (session.totalCost != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(FIcons.poundSterling, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Total: £${session.totalCost!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
