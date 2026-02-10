import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/service_request.dart';

/// Service for managing service requests (waiter calls, etc.)
class ServiceRequestService {
  final ApiClient _apiClient;

  ServiceRequestService(this._apiClient);

  /// Create a new service request
  Future<ServiceRequestResponse> createRequest(CreateServiceRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'service-requests',
      data: request.toJson(),
    );

    return ServiceRequestResponse.fromJson(response.data!);
  }
}

/// Provider for service request service
final serviceRequestServiceProvider = Provider<ServiceRequestService>((ref) {
  final apiClient = ref.watch(notificationsApiProvider);
  return ServiceRequestService(apiClient);
});

/// State for tracking request submission
class ServiceRequestState {
  final bool isLoading;
  final String? error;
  final ServiceRequestResponse? lastRequest;

  const ServiceRequestState({
    this.isLoading = false,
    this.error,
    this.lastRequest,
  });

  ServiceRequestState copyWith({
    bool? isLoading,
    String? error,
    ServiceRequestResponse? lastRequest,
  }) {
    return ServiceRequestState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRequest: lastRequest ?? this.lastRequest,
    );
  }
}

/// Notifier for managing service request state
class ServiceRequestNotifier extends Notifier<ServiceRequestState> {
  late final ServiceRequestService _service;

  @override
  ServiceRequestState build() {
    _service = ref.watch(serviceRequestServiceProvider);
    return const ServiceRequestState();
  }

  /// Submit a service request
  Future<bool> submitRequest(CreateServiceRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.createRequest(request);
      state = state.copyWith(isLoading: false, lastRequest: response);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.statusCode == 400 ? 'cooldown' : 'error',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'error',
      );
      return false;
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for service request notifier
final serviceRequestProvider =
    NotifierProvider<ServiceRequestNotifier, ServiceRequestState>(ServiceRequestNotifier.new);
