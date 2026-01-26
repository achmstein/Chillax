import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/room.dart';

/// Rooms state
class RoomsState {
  final bool isLoading;
  final String? error;
  final List<Room> rooms;
  final List<RoomSession> activeSessions;
  final List<RoomSession>? sessionHistory;
  final bool isLoadingHistory;

  const RoomsState({
    this.isLoading = false,
    this.error,
    this.rooms = const [],
    this.activeSessions = const [],
    this.sessionHistory,
    this.isLoadingHistory = false,
  });

  RoomsState copyWith({
    bool? isLoading,
    String? error,
    List<Room>? rooms,
    List<RoomSession>? activeSessions,
    List<RoomSession>? sessionHistory,
    bool? isLoadingHistory,
  }) {
    return RoomsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rooms: rooms ?? this.rooms,
      activeSessions: activeSessions ?? this.activeSessions,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

/// Rooms provider
class RoomsNotifier extends Notifier<RoomsState> {
  late final ApiClient _api;

  @override
  RoomsState build() {
    _api = ref.read(roomsApiProvider);
    return const RoomsState();
  }

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _api.get(''),
        _api.get('sessions/active'),
      ]);

      final roomsData = results[0].data as List<dynamic>;
      final sessionsData = results[1].data as List<dynamic>;

      final rooms = roomsData
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList();

      final sessions = sessionsData
          .map((e) => RoomSession.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        rooms: rooms,
        activeSessions: sessions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load rooms: $e',
      );
    }
  }

  Future<bool> reserveRoom(int roomId) async {
    try {
      await _api.post('$roomId/reserve', data: {
        'reservationTime': DateTime.now().toIso8601String(),
      });
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to reserve room: $e');
      return false;
    }
  }

  Future<bool> startSession(int sessionId) async {
    try {
      await _api.post('sessions/$sessionId/start');
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to start session: $e');
      return false;
    }
  }

  Future<bool> endSession(int sessionId) async {
    try {
      await _api.post('sessions/$sessionId/end');
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to end session: $e');
      return false;
    }
  }

  Future<bool> cancelSession(int sessionId) async {
    try {
      await _api.post('sessions/$sessionId/cancel');
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel session: $e');
      return false;
    }
  }

  Future<bool> createRoom(Room room) async {
    try {
      await _api.post('', data: room.toJson());
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create room: $e');
      return false;
    }
  }

  Future<bool> updateRoom(Room room) async {
    try {
      await _api.put('${room.id}', data: room.toJson());
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update room: $e');
      return false;
    }
  }

  Future<bool> deleteRoom(int roomId) async {
    try {
      await _api.delete('$roomId');
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete room: $e');
      return false;
    }
  }

  /// Start a walk-in session directly (without reservation)
  Future<bool> startWalkInSession(int roomId) async {
    try {
      await _api.post('$roomId/walk-in');
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to start walk-in session: $e');
      return false;
    }
  }

  /// Load session history for a specific room
  Future<void> loadSessionHistory(int roomId) async {
    state = state.copyWith(isLoadingHistory: true, sessionHistory: null);

    try {
      final response = await _api.get('$roomId/sessions/history');
      final historyData = response.data as List<dynamic>;
      final history = historyData
          .map((e) => RoomSession.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoadingHistory: false,
        sessionHistory: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        sessionHistory: [],
      );
    }
  }

  /// Clear session history when closing detail sheet
  void clearSessionHistory() {
    state = state.copyWith(sessionHistory: null);
  }
}

/// Rooms provider
final roomsProvider = NotifierProvider<RoomsNotifier, RoomsState>(RoomsNotifier.new);
