import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/room.dart';

/// Abstract room repository
abstract class RoomRepository {
  Future<List<Room>> getRooms();
  Future<List<Room>> getAvailableRooms();
  Future<Room> getRoom(int id);
  Future<int> reserveRoom(int roomId);
  Future<List<RoomSession>> getMySessions();
  Future<void> cancelReservation(int sessionId);
  Future<SessionPreview?> getSessionPreview(String accessCode);
  Future<JoinSessionResult> joinSession(String accessCode);
  Future<void> leaveSession(int sessionId);
}

/// API-backed room repository
class ApiRoomRepository implements RoomRepository {
  final ApiClient _apiClient;

  ApiRoomRepository(this._apiClient);

  /// Get all rooms
  @override
  Future<List<Room>> getRooms() async {
    final response = await _apiClient.get<List<dynamic>>(
      '',
    );

    return (response.data ?? [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get available rooms
  @override
  Future<List<Room>> getAvailableRooms() async {
    final response = await _apiClient.get<List<dynamic>>(
      'available',
    );

    return (response.data ?? [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get room by ID
  @override
  Future<Room> getRoom(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$id',
    );

    return Room.fromJson(response.data!);
  }

  /// Reserve a room (immediate - customer has 15 min to arrive)
  @override
  Future<int> reserveRoom(int roomId) async {
    final response = await _apiClient.post<int>(
      '$roomId/reserve',
    );

    return response.data!;
  }

  /// Get customer's sessions
  @override
  Future<List<RoomSession>> getMySessions() async {
    final response = await _apiClient.get<List<dynamic>>(
      'sessions/my',
    );

    return (response.data ?? [])
        .map((e) => RoomSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cancel reservation (customer can only cancel their own reservations)
  @override
  Future<void> cancelReservation(int sessionId) async {
    await _apiClient.post('sessions/my/$sessionId/cancel');
  }

  /// Get session preview by access code
  @override
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
  @override
  Future<JoinSessionResult> joinSession(String accessCode) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'sessions/join',
      data: {'accessCode': accessCode},
    );
    return JoinSessionResult.fromJson(response.data!);
  }

  /// Leave a session
  @override
  Future<void> leaveSession(int sessionId) async {
    await _apiClient.post('sessions/$sessionId/leave');
  }
}

/// Provider for room repository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final apiClient = ref.watch(roomsApiProvider);
  return ApiRoomRepository(apiClient);
});

/// Provider for all rooms
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final service = ref.watch(roomRepositoryProvider);
  return service.getRooms();
});

/// Provider for available rooms
final availableRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final service = ref.watch(roomRepositoryProvider);
  return service.getAvailableRooms();
});

/// Provider for customer sessions
final mySessionsProvider = NotifierProvider<MySessionsNotifier, AsyncValue<List<RoomSession>>>(MySessionsNotifier.new);

/// Sessions notifier - refreshes on demand (app resume, screen focus, pull-to-refresh)
class MySessionsNotifier extends Notifier<AsyncValue<List<RoomSession>>> {
  late final RoomRepository _roomService;

  @override
  AsyncValue<List<RoomSession>> build() {
    _roomService = ref.watch(roomRepositoryProvider);
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
  late final RoomRepository _roomService;

  @override
  ReservationState build() {
    _roomService = ref.watch(roomRepositoryProvider);
    return const ReservationState();
  }

  /// Reserve a room (immediate - customer has 15 min to arrive)
  Future<bool> reserveRoom(int roomId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reservationId = await _roomService.reserveRoom(roomId);
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
