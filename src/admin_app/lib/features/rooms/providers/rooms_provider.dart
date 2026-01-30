import 'package:flutter/foundation.dart';
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
  final bool hasMoreHistory;
  final int historyPage;

  const RoomsState({
    this.isLoading = false,
    this.error,
    this.rooms = const [],
    this.activeSessions = const [],
    this.sessionHistory,
    this.isLoadingHistory = false,
    this.hasMoreHistory = false,
    this.historyPage = 0,
  });

  RoomsState copyWith({
    bool? isLoading,
    String? error,
    List<Room>? rooms,
    List<RoomSession>? activeSessions,
    List<RoomSession>? sessionHistory,
    bool? isLoadingHistory,
    bool? hasMoreHistory,
    int? historyPage,
  }) {
    return RoomsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rooms: rooms ?? this.rooms,
      activeSessions: activeSessions ?? this.activeSessions,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      historyPage: historyPage ?? this.historyPage,
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
      debugPrint('Failed to load rooms: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> reserveRoom(int roomId) async {
    try {
      await _api.post('$roomId/reserve');
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to reserve room: $e');
      return false;
    }
  }

  Future<bool> startSession(int sessionId) async {
    try {
      await _api.post('sessions/$sessionId/start');
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to start session: $e');
      return false;
    }
  }

  Future<bool> endSession(int sessionId) async {
    try {
      await _api.post('sessions/$sessionId/end');
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to end session: $e');
      return false;
    }
  }

  Future<bool> cancelSession(int sessionId) async {
    try {
      await _api.post('sessions/$sessionId/cancel');
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to cancel session: $e');
      return false;
    }
  }

  Future<bool> createRoom(Room room) async {
    try {
      await _api.post('', data: room.toJson());
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to create room: $e');
      return false;
    }
  }

  Future<bool> updateRoom(Room room) async {
    try {
      await _api.put('${room.id}', data: room.toJson());
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to update room: $e');
      return false;
    }
  }

  Future<bool> deleteRoom(int roomId) async {
    try {
      await _api.delete('$roomId');
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to delete room: $e');
      return false;
    }
  }

  /// Start a walk-in session directly (without reservation)
  Future<bool> startWalkInSession(int roomId) async {
    try {
      await _api.post('sessions/walk-in/$roomId');
      await loadRooms();
      return true;
    } catch (e) {
      debugPrint('Failed to start walk-in session: $e');
      return false;
    }
  }

  static const int _historyPageSize = 20;

  /// Load session history for a specific room
  Future<void> loadSessionHistory(int roomId, {bool loadMore = false}) async {
    final currentPage = loadMore ? state.historyPage + 1 : 0;
    final currentHistory = loadMore ? (state.sessionHistory ?? []) : <RoomSession>[];

    state = state.copyWith(
      isLoadingHistory: true,
      sessionHistory: loadMore ? currentHistory : null,
      historyPage: currentPage,
    );

    try {
      final response = await _api.get(
        '$roomId/sessions/history',
        queryParameters: {'limit': _historyPageSize},
      );
      final historyData = response.data as List<dynamic>;
      final newHistory = historyData
          .map((e) => RoomSession.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoadingHistory: false,
        sessionHistory: [...currentHistory, ...newHistory],
        hasMoreHistory: newHistory.length >= _historyPageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        sessionHistory: currentHistory.isEmpty ? [] : currentHistory,
        hasMoreHistory: false,
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
