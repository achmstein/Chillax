/// Room status
enum RoomStatus {
  available(1, 'Available'),
  occupied(2, 'Occupied'),
  reserved(3, 'Reserved'),
  maintenance(4, 'Maintenance');

  final int value;
  final String label;

  const RoomStatus(this.value, this.label);

  static RoomStatus fromValue(int value) {
    return RoomStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RoomStatus.available,
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

/// Room model
class Room {
  final int id;
  final String name;
  final String? description;
  final RoomStatus status;
  final double hourlyRate;
  final String? pictureUri;

  Room({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.hourlyRate,
    this.pictureUri,
  });

  Room copyWith({
    int? id,
    String? name,
    String? description,
    RoomStatus? status,
    double? hourlyRate,
    String? pictureUri,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      pictureUri: pictureUri ?? this.pictureUri,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: RoomStatus.fromValue(json['status'] as int),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      pictureUri: json['pictureUri'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'hourlyRate': hourlyRate,
      'pictureFileName': pictureUri,
    };
  }
}

/// Room session model
class RoomSession {
  final int id;
  final int roomId;
  final String roomName;
  final DateTime reservationTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? totalCost;
  final SessionStatus status;
  final double hourlyRate;

  RoomSession({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.reservationTime,
    this.startTime,
    this.endTime,
    this.totalCost,
    required this.status,
    this.hourlyRate = 0,
  });

  /// Calculate duration if session has started
  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
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

  /// Calculate live cost based on duration
  double get liveCost {
    final d = duration;
    if (d == null || hourlyRate == 0) return totalCost ?? 0;
    return (d.inSeconds / 3600) * hourlyRate;
  }

  factory RoomSession.fromJson(Map<String, dynamic> json) {
    return RoomSession(
      id: json['id'] as int,
      roomId: json['roomId'] as int,
      roomName: json['roomName'] as String? ?? 'Room ${json['roomId']}',
      reservationTime: DateTime.parse(json['reservationTime'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      status: SessionStatus.fromValue(json['status'] as int),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
    );
  }
}
