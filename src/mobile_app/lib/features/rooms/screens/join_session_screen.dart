import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/theme/app_theme.dart';
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
    if (code.length != 6) {
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
      final service = ref.read(roomServiceProvider);
      final preview = await service.getSessionPreview(code);

      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoadingPreview = false;
          _error = preview == null ? 'Session not found' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _preview = null;
          _isLoadingPreview = false;
          _error = 'Failed to fetch session';
        });
      }
    }
  }

  Future<void> _joinSession() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final service = ref.read(roomServiceProvider);
      await service.joinSession(code);

      if (mounted) {
        // Refresh sessions and go back
        ref.read(mySessionsProvider.notifier).refresh();
        ref.refresh(roomsProvider);
        Navigator.pop(context, true);
        showFToast(
          context: context,
          title: const Text('Joined session successfully!'),
          icon: Icon(FIcons.check, color: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = 'Failed to join session';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join Session',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  FIcons.users,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Instructions
              Text(
                'Enter Access Code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask the session owner or staff for the 6-digit code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
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
                  child: Text(
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
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    disabledBackgroundColor: AppTheme.textMuted.withOpacity(0.2),
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
                      : const Text(
                          'Join Session',
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.textMuted.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _error != null
              ? AppTheme.errorColor.withOpacity(0.5)
              : AppTheme.textMuted.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _codeController,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 12,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          hintText: '000000',
          hintStyle: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
            fontFamily: 'monospace',
            color: AppTheme.textMuted.withOpacity(0.3),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.length == 6) {
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.3),
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
              Text(
                'Session Found',
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FIcons.gamepad2,
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.roomName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(FIcons.users, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${preview.memberCount} ${preview.memberCount == 1 ? 'member' : 'members'}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
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
