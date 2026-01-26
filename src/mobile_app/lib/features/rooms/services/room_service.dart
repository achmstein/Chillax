import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/room.dart';

/// Room service
class RoomService {
  final ApiClient _apiClient;

  RoomService(this._apiClient);

  /// Get all rooms
  Future<List<Room>> getRooms() async {
    final response = await _apiClient.get<List<dynamic>>(
      '',
    );

    return (response.data ?? [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get available rooms
  Future<List<Room>> getAvailableRooms() async {
    final response = await _apiClient.get<List<dynamic>>(
      'available',
    );

    return (response.data ?? [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get room by ID
  Future<Room> getRoom(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$id',
    );

    return Room.fromJson(response.data!);
  }

  /// Reserve a room (same-day only)
  Future<int> reserveRoom(int roomId, DateTime scheduledStartTime) async {
    // Enforce same-day only booking
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(scheduledStartTime.year, scheduledStartTime.month, scheduledStartTime.day);

    if (bookingDay.isAfter(today)) {
      throw Exception('Reservations can only be made for today');
    }

    final response = await _apiClient.post<int>(
      '$roomId/reserve',
      data: {
        'scheduledStartTime': scheduledStartTime.toIso8601String(),
      },
    );

    return response.data!;
  }

  /// Get customer's sessions
  Future<List<RoomSession>> getMySessions() async {
    final response = await _apiClient.get<List<dynamic>>(
      'sessions/my',
    );

    return (response.data ?? [])
        .map((e) => RoomSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cancel reservation
  Future<void> cancelReservation(int sessionId) async {
    await _apiClient.post('sessions/$sessionId/cancel');
  }

  /// Get session preview by access code
  Future<SessionPreview?> getSessionPreview(String accessCode) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'sessions/by-code/$accessCode',
      );
      return SessionPreview.fromJson(response.data!);
    } catch (e) {
      return null;
    }
  }

  /// Join a session via access code
  Future<JoinSessionResult> joinSession(String accessCode) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'sessions/join',
      data: {'accessCode': accessCode},
    );
    return JoinSessionResult.fromJson(response.data!);
  }

  /// Leave a session
  Future<void> leaveSession(int sessionId) async {
    await _apiClient.post('sessions/$sessionId/leave');
  }
}

/// Provider for room service
final roomServiceProvider = Provider<RoomService>((ref) {
  final apiClient = ref.watch(roomsApiProvider);
  return RoomService(apiClient);
});

/// Provider for all rooms
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final service = ref.watch(roomServiceProvider);
  return service.getRooms();
});

/// Provider for available rooms
final availableRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final service = ref.watch(roomServiceProvider);
  return service.getAvailableRooms();
});

/// Provider for customer sessions
final mySessionsProvider = NotifierProvider<MySessionsNotifier, AsyncValue<List<RoomSession>>>(MySessionsNotifier.new);

/// Sessions notifier - refreshes on demand (app resume, screen focus, pull-to-refresh)
class MySessionsNotifier extends Notifier<AsyncValue<List<RoomSession>>> {
  late final RoomService _roomService;

  @override
  AsyncValue<List<RoomSession>> build() {
    _roomService = ref.watch(roomServiceProvider);
    _loadSessions();
    return const AsyncValue.loading();
  }

  Future<void> _loadSessions({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }

    try {
      final sessions = await _roomService.getMySessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      if (!silent) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refresh sessions (silent - no loading indicator)
  Future<void> refresh() async {
    await _loadSessions(silent: true);
  }

  /// Force refresh with loading indicator
  Future<void> forceRefresh() async {
    await _loadSessions(silent: false);
  }
}

/// Reservation state
class ReservationState {
  final bool isLoading;
  final String? error;
  final int? reservationId;

  const ReservationState({
    this.isLoading = false,
    this.error,
    this.reservationId,
  });

  ReservationState copyWith({
    bool? isLoading,
    String? error,
    int? reservationId,
  }) {
    return ReservationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      reservationId: reservationId ?? this.reservationId,
    );
  }
}

/// Reservation notifier
class ReservationNotifier extends Notifier<ReservationState> {
  late final RoomService _roomService;

  @override
  ReservationState build() {
    _roomService = ref.watch(roomServiceProvider);
    return const ReservationState();
  }

  /// Reserve a room (same-day only)
  Future<bool> reserveRoom(int roomId, DateTime scheduledStartTime) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reservationId = await _roomService.reserveRoom(roomId, scheduledStartTime);
      state = state.copyWith(isLoading: false, reservationId: reservationId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const ReservationState();
  }
}

/// Provider for reservation
final reservationProvider =
    NotifierProvider<ReservationNotifier, ReservationState>(ReservationNotifier.new);
