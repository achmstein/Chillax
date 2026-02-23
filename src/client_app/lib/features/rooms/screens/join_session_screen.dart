import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../models/room.dart';
import '../services/room_service.dart';

/// Screen for joining a session via access code
class JoinSessionScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const JoinSessionScreen({super.key, this.initialCode});

  @override
  ConsumerState<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  SessionPreview? _preview;
  bool _isLoadingPreview = false;
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      _fetchPreview();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() {
        _preview = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoadingPreview = true;
      _error = null;
    });

    try {
      final service = ref.read(roomRepositoryProvider);
      final preview = await service.getSessionPreview(code);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _preview = preview;
          _isLoadingPreview = false;
          _error = preview == null ? l10n.sessionNotFound : null;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _preview = null;
          _isLoadingPreview = false;
          _error = l10n.failedToFetchSession;
        });
      }
    }
  }

  Future<void> _joinSession() async {
    final code = _codeController.text.trim();
    if (code.length != 4) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final service = ref.read(roomRepositoryProvider);
      await service.joinSession(code);

      if (mounted) {
        // Refresh sessions and go back
        final l10n = AppLocalizations.of(context)!;
        ref.read(mySessionsProvider.notifier).refresh();
        ref.invalidate(roomsProvider);
        Navigator.pop(context, true);
        showFToast(
          context: context,
          title: Text(l10n.joinedSessionSuccessfully),
          icon: Icon(FIcons.check, color: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isJoining = false;
          _error = l10n.failedToJoinSession;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(FIcons.arrowLeft, color: colors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          l10n.joinSession,
          style: TextStyle(color: colors.foreground, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  FIcons.users,
                  size: 40,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Instructions
              AppText(
                l10n.enterAccessCode,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                l10n.accessCodeDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),

              // Code input
              _buildCodeInput(),
              const SizedBox(height: 16),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppText(
                    _error!,
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 14,
                    ),
                  ),
                ),

              // Loading indicator for preview
              if (_isLoadingPreview)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),

              // Session preview
              if (_preview != null) _buildSessionPreview(),

              const Spacer(),

              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _preview != null && !_isJoining ? _joinSession : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    disabledBackgroundColor: colors.mutedForeground.withValues(alpha: 0.2),
                  ),
                  child: _isJoining
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: colors.primaryForeground,
                            strokeWidth: 2,
                          ),
                        )
                      : AppText(
                          l10n.joinSession,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildCodeInput() {
    final colors = context.theme.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.mutedForeground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _error != null
              ? AppTheme.errorColor.withValues(alpha: 0.5)
              : colors.mutedForeground.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _codeController,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 4,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 16,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          hintText: '0000',
          hintStyle: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 16,
            color: colors.mutedForeground.withValues(alpha: 0.3),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.length == 4) {
            _focusNode.unfocus();
            _fetchPreview();
          } else {
            setState(() {
              _preview = null;
              _error = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildSessionPreview() {
    final preview = _preview!;
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successColor.withValues(alpha: 0.1),
            AppTheme.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Success indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FIcons.check, size: 18, color: AppTheme.successColor),
              const SizedBox(width: 8),
              AppText(
                l10n.sessionFound,
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Room name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FIcons.gamepad2,
                  size: 24,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      preview.roomName.localized(context),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(FIcons.users, size: 14, color: colors.mutedForeground),
                        const SizedBox(width: 4),
                        AppText(
                          l10n.memberCountFormat(preview.memberCount),
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
