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
      '/api/rooms',
    );

    return (response.data ?? [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get available rooms
  Future<List<Room>> getAvailableRooms() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/rooms/available',
    );

    return (response.data ?? [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get room by ID
  Future<Room> getRoom(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/rooms/$id',
    );

    return Room.fromJson(response.data!);
  }

  /// Reserve a room
  Future<RoomSession> reserveRoom(int roomId, DateTime reservationTime) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/rooms/$roomId/reserve',
      data: {
        'reservationTime': reservationTime.toIso8601String(),
      },
    );

    return RoomSession.fromJson(response.data!);
  }

  /// Get customer's sessions
  Future<List<RoomSession>> getMySessions() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/sessions/my',
    );

    return (response.data ?? [])
        .map((e) => RoomSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cancel reservation
  Future<void> cancelReservation(int sessionId) async {
    await _apiClient.post('/api/sessions/$sessionId/cancel');
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
final mySessionsProvider = FutureProvider<List<RoomSession>>((ref) async {
  final service = ref.watch(roomServiceProvider);
  return service.getMySessions();
});

/// Reservation state
class ReservationState {
  final bool isLoading;
  final String? error;
  final RoomSession? session;

  const ReservationState({
    this.isLoading = false,
    this.error,
    this.session,
  });

  ReservationState copyWith({
    bool? isLoading,
    String? error,
    RoomSession? session,
  }) {
    return ReservationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      session: session ?? this.session,
    );
  }
}

/// Reservation notifier
class ReservationNotifier extends StateNotifier<ReservationState> {
  final RoomService _roomService;

  ReservationNotifier(this._roomService) : super(const ReservationState());

  /// Reserve a room
  Future<bool> reserveRoom(int roomId, DateTime reservationTime) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _roomService.reserveRoom(roomId, reservationTime);
      state = state.copyWith(isLoading: false, session: session);
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
    StateNotifierProvider<ReservationNotifier, ReservationState>((ref) {
  final roomService = ref.watch(roomServiceProvider);
  return ReservationNotifier(roomService);
});
