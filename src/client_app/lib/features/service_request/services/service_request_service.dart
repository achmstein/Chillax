import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/service_request.dart';

/// Abstract interface for service request operations
abstract class ServiceRequestRepository {
  Future<ServiceRequestResponse> createRequest(CreateServiceRequest request);
}

/// Service request repository implementation using API client
class ApiServiceRequestRepository implements ServiceRequestRepository {
  final ApiClient _apiClient;

  ApiServiceRequestRepository(this._apiClient);

  /// Create a new service request
  @override
  Future<ServiceRequestResponse> createRequest(CreateServiceRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'service-requests',
      data: request.toJson(),
    );

    return ServiceRequestResponse.fromJson(response.data!);
  }
}

/// Provider for service request repository
final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>((ref) {
  final apiClient = ref.watch(notificationsApiProvider);
  return ApiServiceRequestRepository(apiClient);
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
  late ServiceRequestRepository _service;

  @override
  ServiceRequestState build() {
    _service = ref.watch(serviceRequestRepositoryProvider);
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
