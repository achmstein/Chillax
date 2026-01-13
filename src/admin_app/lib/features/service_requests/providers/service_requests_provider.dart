import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/service_request.dart';

/// State for service requests
class ServiceRequestsState {
  final List<ServiceRequest> requests;
  final bool isLoading;
  final String? error;

  const ServiceRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  ServiceRequestsState copyWith({
    List<ServiceRequest>? requests,
    bool? isLoading,
    String? error,
  }) {
    return ServiceRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get pending requests only
  List<ServiceRequest> get pendingRequests =>
      requests.where((r) => r.status == ServiceRequestStatus.pending).toList();

  /// Get acknowledged requests
  List<ServiceRequest> get acknowledgedRequests =>
      requests.where((r) => r.status == ServiceRequestStatus.acknowledged).toList();
}

/// Service requests notifier
class ServiceRequestsNotifier extends StateNotifier<ServiceRequestsState> {
  final ApiClient _apiClient;

  ServiceRequestsNotifier(this._apiClient) : super(const ServiceRequestsState());

  /// Load pending service requests
  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get<List<dynamic>>('service-requests/pending');

      final requests = (response.data ?? [])
          .map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load service requests: $e',
      );
    }
  }

  /// Acknowledge a service request
  Future<bool> acknowledgeRequest(int requestId) async {
    try {
      await _apiClient.put('service-requests/$requestId/acknowledge');
      await loadRequests(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to acknowledge request: $e');
      return false;
    }
  }

  /// Complete a service request
  Future<bool> completeRequest(int requestId) async {
    try {
      await _apiClient.put('service-requests/$requestId/complete');
      await loadRequests(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to complete request: $e');
      return false;
    }
  }
}

/// Provider for service requests
final serviceRequestsProvider =
    StateNotifierProvider<ServiceRequestsNotifier, ServiceRequestsState>((ref) {
  final apiClient = ref.watch(notificationsApiProvider);
  return ServiceRequestsNotifier(apiClient);
});
