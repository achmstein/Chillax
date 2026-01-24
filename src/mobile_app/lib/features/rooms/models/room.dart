/// Room display status (computed at query time)
enum RoomDisplayStatus {
  available(1, 'Available'),
  occupied(2, 'Occupied'),
  reservedSoon(3, 'Reserved Soon'),
  maintenance(4, 'Maintenance');

  final int value;
  final String label;

  const RoomDisplayStatus(this.value, this.label);

  static RoomDisplayStatus fromValue(int value) {
    return RoomDisplayStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RoomDisplayStatus.available,
    );
  }
}

/// Session status
enum SessionStatus {
  reserved(1, 'Reserved'),
  active(2, 'Active'),
  completed(3, 'Completed'),
  cancelled(4, 'Cancelled');

  final int value;
  final String label;

  const SessionStatus(this.value, this.label);

  static SessionStatus fromValue(int value) {
    return SessionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SessionStatus.reserved,
    );
  }
}

/// Room model - updated for time-aware availability
class Room {
  final int id;
  final String name;
  final String? description;
  final RoomDisplayStatus displayStatus;
  final double hourlyRate;
  final DateTime? nextReservationTime;

  Room({
    required this.id,
    required this.name,
    this.description,
    required this.displayStatus,
    required this.hourlyRate,
    this.nextReservationTime,
  });

  /// Can the user book this room now?
  bool get canBookNow => displayStatus == RoomDisplayStatus.available;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayStatus: RoomDisplayStatus.fromValue(json['displayStatus'] as int),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      nextReservationTime: json['nextReservationTime'] != null
          ? DateTime.parse(json['nextReservationTime'] as String)
          : null,
    );
  }
}

/// Room session/reservation model
class RoomSession {
  final int id;
  final int roomId;
  final String roomName;
  final double hourlyRate;
  final DateTime createdAt;
  final DateTime scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? endTime;
  final double? totalCost;
  final SessionStatus status;
  final String? notes;
  final String? accessCode;

  RoomSession({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.hourlyRate,
    required this.createdAt,
    required this.scheduledStartTime,
    this.actualStartTime,
    this.endTime,
    this.totalCost,
    required this.status,
    this.notes,
    this.accessCode,
  });

  /// For backward compatibility with existing code
  DateTime get reservationTime => scheduledStartTime;

  /// Calculate duration if session is active or completed
  Duration? get duration {
    if (actualStartTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(actualStartTime!);
  }

  /// Format duration as HH:MM:SS
  String get formattedDuration {
    final d = duration;
    if (d == null) return '--:--:--';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  factory RoomSession.fromJson(Map<String, dynamic> json) {
    return RoomSession(
      id: json['id'] as int,
      roomId: json['roomId'] as int,
      roomName: json['roomName'] as String? ?? 'Room ${json['roomId']}',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledStartTime: DateTime.parse(json['scheduledStartTime'] as String),
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      status: SessionStatus.fromValue(json['status'] as int),
      notes: json['notes'] as String?,
      accessCode: json['accessCode'] as String?,
    );
  }
}

/// Reserve room request
class ReserveRoomRequest {
  final DateTime scheduledStartTime;
  final String? notes;

  ReserveRoomRequest({required this.scheduledStartTime, this.notes});

  Map<String, dynamic> toJson() {
    return {
      'scheduledStartTime': scheduledStartTime.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Session preview (before joining)
class SessionPreview {
  final int sessionId;
  final int roomId;
  final String roomName;
  final DateTime startTime;
  final int memberCount;

  SessionPreview({
    required this.sessionId,
    required this.roomId,
    required this.roomName,
    required this.startTime,
    required this.memberCount,
  });

  factory SessionPreview.fromJson(Map<String, dynamic> json) {
    return SessionPreview(
      sessionId: json['sessionId'] as int,
      roomId: json['roomId'] as int,
      roomName: json['roomName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      memberCount: json['memberCount'] as int,
    );
  }
}

/// Result of joining a session
class JoinSessionResult {
  final int reservationId;
  final int roomId;
  final String roomName;
  final bool isOwner;
  final DateTime startTime;

  JoinSessionResult({
    required this.reservationId,
    required this.roomId,
    required this.roomName,
    required this.isOwner,
    required this.startTime,
  });

  factory JoinSessionResult.fromJson(Map<String, dynamic> json) {
    return JoinSessionResult(
      reservationId: json['reservationId'] as int,
      roomId: json['roomId'] as int,
      roomName: json['roomName'] as String,
      isOwner: json['isOwner'] as bool,
      startTime: DateTime.parse(json['startTime'] as String),
    );
  }
}
