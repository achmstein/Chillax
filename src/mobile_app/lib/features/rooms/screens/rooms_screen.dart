import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/services/notification_service.dart';
import '../../service_request/models/service_request.dart';
import '../../service_request/services/service_request_service.dart';
import '../models/room.dart';
import '../services/room_service.dart';

/// Rooms screen for viewing and reserving PlayStation rooms
class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isJoining = false;
  String? _joinError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh sessions when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      ref.read(mySessionsProvider.notifier).refresh();
      ref.invalidate(roomsProvider);
    }
  }

  Future<void> _joinSession() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _joinError = l10n.enterSixDigitCode);
      return;
    }

    setState(() {
      _isJoining = true;
      _joinError = null;
    });

    try {
      final service = ref.read(roomServiceProvider);
      await service.joinSession(code);

      if (mounted) {
        _codeController.clear();
        _codeFocusNode.unfocus();
        ref.read(mySessionsProvider.notifier).refresh();
        ref.invalidate(roomsProvider);
        showFToast(
          context: context,
          title: Text(l10n.joinedSession),
          icon: Icon(FIcons.check, color: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _joinError = l10n.invalidCode);
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final sessionsAsync = ref.watch(mySessionsProvider);
    final l10n = AppLocalizations.of(context)!;

    // Determine if user has an active session
    final hasActiveSession = sessionsAsync.whenOrNull(
      data: (sessions) => sessions.any((s) => s.status == SessionStatus.active),
    ) ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: !hasActiveSession ? _buildJoinSessionBar() : null,
      body: Column(
        children: [
          // Header
          FHeader(
            title: AppText(l10n.rooms, style: TextStyle(fontSize: 18)),
          ),

          // Content
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _buildRoomsList(context, roomsAsync, null, null),
              data: (sessions) {
                final activeSession = sessions
                    .where((s) => s.status == SessionStatus.active)
                    .firstOrNull;
                final reservedSession = sessions
                    .where((s) => s.status == SessionStatus.reserved)
                    .firstOrNull;

                // If user has active session, show session view
                if (activeSession != null) {
                  return _ActiveSessionView(session: activeSession);
                }

                // If user has reserved session, show reservation + rooms
                return _buildRoomsList(context, roomsAsync, reservedSession, null);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinSessionBar() {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
          children: [
            // Code input
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: _joinError != null
                      ? Border.all(color: AppTheme.errorColor.withValues(alpha: 0.5))
                      : null,
                ),
                child: TextField(
                  controller: _codeController,
                  focusNode: _codeFocusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    hintText: AppLocalizations.of(context)!.enterCode,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) {
                    if (_joinError != null) {
                      setState(() => _joinError = null);
                    }
                  },
                  onSubmitted: (_) => _joinSession(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Join button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isJoining ? null : _joinSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _isJoining
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : AppText(
                        AppLocalizations.of(context)!.join,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildRoomsList(
    BuildContext context,
    AsyncValue<List<Room>> roomsAsync,
    RoomSession? reservedSession,
    RoomSession? activeSession,
  ) {
    return roomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FIcons.circleAlert, size: 48, color: context.theme.colors.mutedForeground),
            const SizedBox(height: 16),
            AppText(AppLocalizations.of(context)!.failedToLoadRooms),
            const SizedBox(height: 16),
            FButton(
              onPress: () => ref.refresh(roomsProvider),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
      data: (rooms) {
        final allUnavailable = rooms.isNotEmpty &&
            rooms.every((r) => !r.canBookNow);

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          backgroundColor: context.theme.colors.background,
          onRefresh: () async {
            ref.invalidate(roomsProvider);
            await ref.read(mySessionsProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _getItemCount(rooms, reservedSession, allUnavailable),
            itemBuilder: (context, index) {
              int currentIndex = index;

              // Reserved session banner (always first if exists)
              if (reservedSession != null && currentIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _ReservedSessionBanner(session: reservedSession),
                );
              }
              if (reservedSession != null) currentIndex--;

              // Notify me banner (if all rooms unavailable)
              if (allUnavailable && currentIndex == 0) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: NotifyMeBanner(),
                );
              }
              if (allUnavailable) currentIndex--;

              // Room items
              final room = rooms[currentIndex];
              return Column(
                children: [
                  RoomListItem(
                    room: room,
                    canReserve: reservedSession == null,
                  ),
                  if (currentIndex < rooms.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: context.theme.colors.border,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  int _getItemCount(List<Room> rooms, RoomSession? reservedSession, bool allUnavailable) {
    int count = rooms.length;
    if (reservedSession != null) count++;
    if (allUnavailable) count++;
    return count;
  }
}

/// Active session view - shown when user is currently playing
class _ActiveSessionView extends ConsumerStatefulWidget {
  final RoomSession session;

  const _ActiveSessionView({required this.session});

  @override
  ConsumerState<_ActiveSessionView> createState() => _ActiveSessionViewState();
}

class _ActiveSessionViewState extends ConsumerState<_ActiveSessionView> {
  Timer? _timer;
  static const _cooldownDuration = 30; // seconds

  // Track cooldown end times for each request type
  final Map<ServiceRequestType, DateTime> _cooldownEndTimes = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Get remaining cooldown seconds for a request type
  int _getCooldownRemaining(ServiceRequestType type) {
    final endTime = _cooldownEndTimes[type];
    if (endTime == null) return 0;

    final remaining = endTime.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Start cooldown for a request type
  void _startCooldown(ServiceRequestType type) {
    _cooldownEndTimes[type] = DateTime.now().add(const Duration(seconds: _cooldownDuration));
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: context.theme.colors.background,
      onRefresh: () => ref.read(mySessionsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main session card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Room name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(FIcons.gamepad2, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      AppText(
                        session.roomName.localized(context),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppText(
                      AppLocalizations.of(context)!.sessionActive,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Access code display
                  if (session.accessCode != null) ...[
                    const SizedBox(height: 20),
                    AppText(
                      AppLocalizations.of(context)!.shareCodeWithFriends,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // Copy to clipboard
                        Clipboard.setData(ClipboardData(text: session.accessCode!));
                        showFToast(
                          context: context,
                          title: Text(AppLocalizations.of(context)!.codeCopied),
                          icon: Icon(FIcons.check, color: AppTheme.successColor),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              session.accessCode!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              FIcons.copy,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Timer
                  AppText(
                    session.formattedDuration,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    AppLocalizations.of(context)!.hourlyRateFormat(session.hourlyRate.toStringAsFixed(0)),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions
            AppText(
              AppLocalizations.of(context)!.needSomething,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons grid
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: FIcons.user,
                    label: AppLocalizations.of(context)!.callWaiter,
                    cooldownSeconds: _getCooldownRemaining(ServiceRequestType.callWaiter),
                    onTap: () => _submitRequest(ServiceRequestType.callWaiter),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: FIcons.gamepad2,
                    label: AppLocalizations.of(context)!.controller,
                    cooldownSeconds: _getCooldownRemaining(ServiceRequestType.controllerChange),
                    onTap: () => _submitRequest(ServiceRequestType.controllerChange),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: FIcons.receipt,
                    label: AppLocalizations.of(context)!.getBill,
                    cooldownSeconds: _getCooldownRemaining(ServiceRequestType.receiptToPay),
                    onTap: () => _submitRequest(ServiceRequestType.receiptToPay),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest(ServiceRequestType type) async {
    // Check if still in cooldown
    if (_getCooldownRemaining(type) > 0) return;

    final session = widget.session;
    final request = CreateServiceRequest(
      sessionId: session.id,
      roomId: session.roomId,
      roomName: session.roomName.en,
      requestType: type,
    );

    final success = await ref.read(serviceRequestProvider.notifier).submitRequest(request);

    if (mounted) {
      if (success) {
        // Start cooldown on success
        _startCooldown(type);
        showFToast(
          context: context,
          title: Text(_getSuccessMessage(type)),
          icon: Icon(FIcons.check, color: AppTheme.successColor),
        );
      } else {
        final error = ref.read(serviceRequestProvider).error;
        showFToast(
          context: context,
          title: Text(error ?? 'Failed to send request'),
          icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
        );
      }
    }
  }

  String _getSuccessMessage(ServiceRequestType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case ServiceRequestType.callWaiter:
        return l10n.waiterNotified;
      case ServiceRequestType.controllerChange:
        return l10n.controllerRequestSent;
      case ServiceRequestType.receiptToPay:
        return l10n.billRequestSent;
    }
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int cooldownSeconds;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.cooldownSeconds = 0,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isPressed = false;

  bool get _isInCooldown => widget.cooldownSeconds > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isInCooldown ? null : (_) => setState(() => _isPressed = true),
      onTapUp: _isInCooldown ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: _isInCooldown ? null : () => setState(() => _isPressed = false),
      onTap: _isInCooldown ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isInCooldown
                ? AppTheme.textMuted.withValues(alpha: 0.15)
                : _isPressed
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : AppTheme.textMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPressed && !_isInCooldown
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              if (_isInCooldown) ...[
                // Show countdown
                AppText(
                  '${widget.cooldownSeconds}s',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ] else ...[
                Icon(widget.icon, size: 24, color: AppTheme.primaryColor),
                const SizedBox(height: 8),
                AppText(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reserved session banner - matches active session card style
class _ReservedSessionBanner extends ConsumerWidget {
  final RoomSession session;

  const _ReservedSessionBanner({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningColor,
            AppTheme.warningColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Room name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(FIcons.gamepad2, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              AppText(
                session.roomName.localized(context),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              AppLocalizations.of(context)!.reserved,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Date and time
          AppText(
            DateFormat('EEEE, MMM d', Localizations.localeOf(context).languageCode).format(session.reservationTime),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AppText(
            DateFormat('h:mm a', Localizations.localeOf(context).languageCode).format(session.reservationTime),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Cancel link
          GestureDetector(
            onTap: () => _cancelReservation(context, ref),
            child: AppText(
              AppLocalizations.of(context)!.cancelReservation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: Text(l10n.cancelReservationQuestion),
        body: Text(l10n.confirmCancelReservation),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(context, false),
            child: Text(l10n.noKeep),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () => Navigator.pop(context, true),
            child: Text(l10n.yesCancel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(roomServiceProvider);
        await service.cancelReservation(session.id);
        ref.read(mySessionsProvider.notifier).refresh();
        ref.invalidate(roomsProvider);
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(l10n.reservationCancelled),
            icon: Icon(FIcons.check, color: AppTheme.successColor),
          );
        }
      } catch (e) {
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(l10n.failedToCancelReservation),
            icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
          );
        }
      }
    }
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
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Builder(
        builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FIcons.bell, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  l10n.allRoomsBusy,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(
            l10n.getNotifiedWhenAvailable,
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
            error: (_, _) => FButton(
              onPress: () => ref.refresh(roomAvailabilitySubscriptionProvider),
              child: Text(l10n.retry),
            ),
            data: (isSubscribed) => isSubscribed
                ? Row(
                    children: [
                      Icon(FIcons.check, size: 16, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          l10n.willBeNotifiedWhenAvailable,
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
                              title: Text(l10n.unsubscribedFromNotifications),
                              icon: Icon(FIcons.check, color: AppTheme.textMuted),
                            );
                          }
                        },
                        child: Text(l10n.cancel),
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
                              title: Text(l10n.youWillBeNotified),
                              icon: Icon(FIcons.bell, color: AppTheme.successColor),
                            );
                          } else {
                            showFToast(
                              context: context,
                              title: Text(l10n.failedToSubscribe),
                              icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FIcons.bell, size: 16),
                          const SizedBox(width: 8),
                          AppText(l10n.notifyMe),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
      },
      ),
    );
  }
}

/// Room list item - minimal design like menu items
class RoomListItem extends ConsumerWidget {
  final Room room;
  final bool canReserve;

  const RoomListItem({
    super.key,
    required this.room,
    this.canReserve = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final isAvailable = room.canBookNow && canReserve;
    final statusColor = _getStatusColor(colors);

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
                    ? colors.primary.withValues(alpha: 0.1)
                    : colors.mutedForeground.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FIcons.gamepad2,
                size: 28,
                color: isAvailable ? colors.primary : colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 12),

            // Room info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    room.name.localized(context),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.foreground,
                    ),
                  ),
                  if (room.description != null) ...[
                    const SizedBox(height: 4),
                    AppText(
                      room.description!.localized(context),
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AppText(
                        AppLocalizations.of(context)!.hourlyRateFormat(room.hourlyRate.toStringAsFixed(0)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        '• ${_getLocalizedStatus(context, room.displayStatus)}',
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
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  FIcons.calendarPlus,
                  color: colors.primaryForeground,
                  size: 18,
                ),
              )
            else if (room.canBookNow && !canReserve)
              // Room is available but user already has reservation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.mutedForeground.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText(
                  AppLocalizations.of(context)!.available,
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic colors) {
    switch (room.displayStatus) {
      case RoomDisplayStatus.available:
        return canReserve ? AppTheme.successColor : colors.mutedForeground;
      case RoomDisplayStatus.occupied:
        return AppTheme.errorColor;
      case RoomDisplayStatus.reserved:
        return AppTheme.warningColor;
      case RoomDisplayStatus.maintenance:
        return colors.mutedForeground;
    }
  }

  String _getLocalizedStatus(BuildContext context, RoomDisplayStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case RoomDisplayStatus.available:
        return l10n.available;
      case RoomDisplayStatus.occupied:
        return l10n.occupied;
      case RoomDisplayStatus.reserved:
        return l10n.reserved;
      case RoomDisplayStatus.maintenance:
        return l10n.maintenance;
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

/// Reservation bottom sheet - immediate reservation with 15 min arrival window
class ReservationSheet extends ConsumerStatefulWidget {
  final Room room;

  const ReservationSheet({super.key, required this.room});

  @override
  ConsumerState<ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends ConsumerState<ReservationSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: colors.mutedForeground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      l10n.reserveRoomName(widget.room.name.localized(context)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(FIcons.x, size: 24, color: colors.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppText(
                l10n.hourlyRateFormat(widget.room.hourlyRate.toStringAsFixed(0)),
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 15,
                ),
              ),
              // Room description
              if (widget.room.description != null) ...[
                const SizedBox(height: 12),
                AppText(
                  widget.room.description!.localized(context),
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Info box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(FIcons.clock, size: 24, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            l10n.fifteenMinutesToArrive,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: colors.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            l10n.reservationCancelledIfNoCheckIn,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reserve button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReserve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: colors.primaryForeground,
                            strokeWidth: 2,
                          ),
                        )
                      : AppText(
                          l10n.reserveNow,
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    final success = await ref
        .read(reservationProvider.notifier)
        .reserveRoom(widget.room.id);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ref.invalidate(roomsProvider);
      ref.read(mySessionsProvider.notifier).refresh();
      showFToast(
        context: context,
        title: Text(l10n.roomReservedSuccess),
        icon: Icon(FIcons.check, color: AppTheme.successColor),
      );
    } else if (mounted) {
      showFToast(
        context: context,
        title: Text(l10n.failedToReserveRoom),
        icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
      );
    }
  }
}
