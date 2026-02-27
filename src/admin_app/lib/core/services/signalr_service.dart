import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../auth/auth_service.dart';
import '../config/app_config.dart';

/// SignalR connection service for realtime admin updates
class SignalRService {
  final Ref _ref;
  HubConnection? _hubConnection;
  bool _isConnecting = false;

  // Event streams for different update types
  final _roomStatusChanged = StreamController<Map<String, dynamic>>.broadcast();
  final _orderStatusChanged = StreamController<Map<String, dynamic>>.broadcast();
  final _serviceRequestCreated = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onRoomStatusChanged => _roomStatusChanged.stream;
  Stream<Map<String, dynamic>> get onOrderStatusChanged => _orderStatusChanged.stream;
  Stream<Map<String, dynamic>> get onServiceRequestCreated => _serviceRequestCreated.stream;

  SignalRService(this._ref);

  /// Connect to the SignalR hub
  Future<void> connect() async {
    if (_hubConnection != null || _isConnecting) return;
    _isConnecting = true;

    try {
      final hubUrl = '${AppConfig.bffBaseUrl}/hub/notifications';

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                final authService = _ref.read(authServiceProvider.notifier);
                return await authService.getAccessToken() ?? '';
              },
            ),
          )
          .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000])
          .build();

      // Register event handlers
      _hubConnection!.on('RoomStatusChanged', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final data = arguments[0];
          if (data is Map<String, dynamic>) {
            _roomStatusChanged.add(data);
          } else if (data is Map) {
            _roomStatusChanged.add(Map<String, dynamic>.from(data));
          }
        }
      });

      _hubConnection!.on('OrderStatusChanged', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final data = arguments[0];
          if (data is Map<String, dynamic>) {
            _orderStatusChanged.add(data);
          } else if (data is Map) {
            _orderStatusChanged.add(Map<String, dynamic>.from(data));
          }
        }
      });

      _hubConnection!.on('ServiceRequestCreated', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final data = arguments[0];
          if (data is Map<String, dynamic>) {
            _serviceRequestCreated.add(data);
          } else if (data is Map) {
            _serviceRequestCreated.add(Map<String, dynamic>.from(data));
          }
        }
      });

      _hubConnection!.onclose(({error}) {
        debugPrint('SignalR connection closed: $error');
      });

      _hubConnection!.onreconnecting(({error}) {
        debugPrint('SignalR reconnecting: $error');
      });

      _hubConnection!.onreconnected(({connectionId}) {
        debugPrint('SignalR reconnected: $connectionId');
        // Re-join groups after reconnect
        _joinGroups();
      });

      await _hubConnection!.start();
      debugPrint('SignalR connected to $hubUrl');

      // Join admin and rooms groups on connect
      await _joinGroups();
    } catch (e) {
      debugPrint('SignalR connection failed: $e');
      _hubConnection = null;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _joinGroups() async {
    try {
      await _hubConnection?.invoke('JoinRoomsGroup');
      await _hubConnection?.invoke('JoinAdminGroup');
    } catch (e) {
      debugPrint('Failed to join SignalR groups: $e');
    }
  }

  /// Reconnect if the connection was lost (e.g. after app resumed from background)
  Future<void> reconnectIfNeeded() async {
    if (_hubConnection == null) return;
    if (_hubConnection!.state == HubConnectionState.Connected) return;
    if (_isConnecting) return;

    _hubConnection = null;
    await connect();
  }

  /// Disconnect from the SignalR hub
  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
    } catch (e) {
      debugPrint('SignalR disconnect error: $e');
    }
    _hubConnection = null;
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _roomStatusChanged.close();
    _orderStatusChanged.close();
    _serviceRequestCreated.close();
  }
}

/// SignalR service provider
final signalRServiceProvider = Provider<SignalRService>((ref) {
  final service = SignalRService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
