import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';
import '../config/app_config.dart';

/// Base API client with authentication interceptor
class ApiClient {
  final Dio _dio;
  final AuthService _authService;

  ApiClient(this._authService, {required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          queryParameters: {'api-version': '1.0'},
        )) {
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('[Dio] $obj'),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          final refreshed = await _authService.refreshToken();
          if (refreshed) {
            // Retry the request
            final token = await _authService.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path,
      {dynamic data, Map<String, dynamic>? headers}) {
    return _dio.post<T>(path,
        data: data, options: headers != null ? Options(headers: headers) : null);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}

/// Providers for API clients
final catalogApiProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider.notifier);
  return ApiClient(authService, baseUrl: AppConfig.catalogApiUrl);
});

final ordersApiProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider.notifier);
  return ApiClient(authService, baseUrl: AppConfig.ordersApiUrl);
});

final roomsApiProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider.notifier);
  return ApiClient(authService, baseUrl: AppConfig.roomsApiUrl);
});

final loyaltyApiProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider.notifier);
  return ApiClient(authService, baseUrl: AppConfig.loyaltyApiUrl);
});

final notificationsApiProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider.notifier);
  return ApiClient(authService, baseUrl: AppConfig.notificationsApiUrl);
});

final accountsApiProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider.notifier);
  return ApiClient(authService, baseUrl: AppConfig.accountsApiUrl);
});

final identityApiProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider.notifier);
  return ApiClient(authService, baseUrl: AppConfig.identityApiUrl);
});
