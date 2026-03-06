import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import '../models/localized_text.dart';
import '../providers/branch_provider.dart';
import '../../features/rooms/models/room.dart';

/// Method channel for native notification management
const _channel = MethodChannel('com.chillax.client/session_notification');

/// Handles the persistent notification shown during active sessions,
/// similar to Spotify's media controls in the notification bar.
class SessionNotificationService {
  final Ref _ref;
  Timer? _updateTimer;
  RoomSession? _activeSession;
  bool _initialized = false;

  SessionNotificationService(this._ref);

  /// Initialize and set up the action handler
  Future<void> initialize() async {
    if (_initialized) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final actionId = call.arguments as String?;
        _handleAction(actionId);
      }
    });

    _initialized = true;
  }

  /// Show or update the session notification
  Future<void> showSessionNotification(RoomSession session, String locale) async {
    _activeSession = session;

    await _saveSessionInfo(session);

    final isArabic = locale == 'ar';
    final roomName = isArabic ? (session.roomName.ar ?? session.roomName.en) : session.roomName.en;

    try {
      await _channel.invokeMethod('show', {
        'roomName': roomName,
        'duration': session.formattedDuration,
        'startTimeMs': session.actualStartTime?.millisecondsSinceEpoch,
        'locale': locale,
        'playerMode': session.currentPlayerMode ?? 'Single',
      });
    } catch (e) {
      debugPrint('Failed to show session notification: $e');
    }

    _startPeriodicUpdate(session, locale);
  }

  /// Dismiss the session notification
  Future<void> dismissNotification() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    _activeSession = null;

    try {
      await _channel.invokeMethod('dismiss');
    } catch (e) {
      debugPrint('Failed to dismiss session notification: $e');
    }

    await _clearSessionInfo();
  }

  /// Start periodic timer to update the notification duration text
  void _startPeriodicUpdate(RoomSession session, String locale) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_activeSession != null) {
        showSessionNotification(_activeSession!, locale);
      }
    });
  }

  /// Handle action from foreground - uses Riverpod container
  void _handleAction(String? actionId) async {
    if (actionId == null || _activeSession == null) return;

    final requestType = _actionToRequestType(actionId);
    if (requestType == null) return;

    try {
      final authService = _ref.read(authServiceProvider.notifier);
      final accessToken = await authService.getAccessToken();
      if (accessToken == null) return;

      final branchId = _ref.read(selectedBranchIdProvider);
      await _sendServiceRequest(
        accessToken: accessToken,
        sessionId: _activeSession!.id,
        roomId: _activeSession!.roomId,
        roomName: _activeSession!.roomName,
        requestType: requestType,
        branchId: branchId,
      );
    } catch (e) {
      debugPrint('Failed to handle notification action: $e');
    }
  }

  /// Map action ID to service request type value
  static int? _actionToRequestType(String actionId) {
    switch (actionId) {
      case 'call_waiter':
        return 1;
      case 'controller':
        return 2;
      case 'get_bill':
        return 3;
      case 'switch_to_multi':
        return 4;
      case 'switch_to_single':
        return 5;
      default:
        return null;
    }
  }

  /// Send a service request directly via API
  static Future<void> _sendServiceRequest({
    required String accessToken,
    required int sessionId,
    required int roomId,
    required LocalizedText roomName,
    required int requestType,
    int? branchId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.notificationsApiUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        if (branchId != null) 'X-Branch-Id': '$branchId',
      },
      queryParameters: {'api-version': '1.0'},
    ));

    await dio.post('service-requests', data: {
      'sessionId': sessionId,
      'roomId': roomId,
      'roomName': roomName.toJson(),
      'requestType': requestType,
    });
  }

  /// Save session info to shared preferences for background action handling
  Future<void> _saveSessionInfo(RoomSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = await _ref.read(authServiceProvider.notifier).getAccessToken();
    final branchId = _ref.read(selectedBranchIdProvider);

    await prefs.setInt('active_session_id', session.id);
    await prefs.setInt('active_session_room_id', session.roomId);
    await prefs.setString('active_session_room_name_en', session.roomName.en);
    if (session.roomName.ar != null) {
      await prefs.setString('active_session_room_name_ar', session.roomName.ar!);
    }
    if (accessToken != null) {
      await prefs.setString('active_session_access_token', accessToken);
    }
    if (branchId != null) {
      await prefs.setInt('active_session_branch_id', branchId);
    }
  }

  /// Clear session info from shared preferences
  Future<void> _clearSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_session_id');
    await prefs.remove('active_session_room_id');
    await prefs.remove('active_session_room_name_en');
    await prefs.remove('active_session_room_name_ar');
    await prefs.remove('active_session_access_token');
    await prefs.remove('active_session_branch_id');
  }

  /// Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
}

/// Provider for session notification service
final sessionNotificationServiceProvider = Provider<SessionNotificationService>((ref) {
  final service = SessionNotificationService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
