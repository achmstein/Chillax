import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Types of service requests users can make
enum ServiceRequestType {
  callWaiter(1, 'Call Waiter', FIcons.user),
  controllerChange(2, 'Controller', FIcons.gamepad2),
  receiptToPay(3, 'Pay Bill', FIcons.receipt);

  final int value;
  final String label;
  final IconData icon;

  const ServiceRequestType(this.value, this.label, this.icon);

  static ServiceRequestType? fromValue(int value) {
    return ServiceRequestType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceRequestType.callWaiter,
    );
  }
}

/// Status of a service request
enum ServiceRequestStatus {
  pending(1),
  acknowledged(2),
  completed(3);

  final int value;

  const ServiceRequestStatus(this.value);
}

/// Request payload for creating a service request
class CreateServiceRequest {
  final int sessionId;
  final int roomId;
  final String roomName;
  final ServiceRequestType requestType;

  CreateServiceRequest({
    required this.sessionId,
    required this.roomId,
    required this.roomName,
    required this.requestType,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'roomId': roomId,
      'roomName': roomName,
      'requestType': requestType.value,
    };
  }
}

/// Service request response from API
class ServiceRequestResponse {
  final int id;
  final String userName;
  final int roomId;
  final String roomName;
  final ServiceRequestType requestType;
  final ServiceRequestStatus status;
  final DateTime createdAt;

  ServiceRequestResponse({
    required this.id,
    required this.userName,
    required this.roomId,
    required this.roomName,
    required this.requestType,
    required this.status,
    required this.createdAt,
  });

  factory ServiceRequestResponse.fromJson(Map<String, dynamic> json) {
    return ServiceRequestResponse(
      id: json['id'] as int,
      userName: json['userName'] as String,
      roomId: json['roomId'] as int,
      roomName: json['roomName'] as String,
      requestType: ServiceRequestType.fromValue(json['requestType'] as int)!,
      status: ServiceRequestStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => ServiceRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
