import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../services/firebase_service.dart';

/// Authentication state
class AuthState {
  final bool isInitializing;
  final bool isAuthenticated;
  final bool isAdmin;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? userId;
  final String? email;
  final String? name;
  final List<String> roles;

  const AuthState({
    this.isInitializing = true,
    this.isAuthenticated = false,
    this.isAdmin = false,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.userId,
    this.email,
    this.name,
    this.roles = const [],
  });

  AuthState copyWith({
    bool? isInitializing,
    bool? isAuthenticated,
    bool? isAdmin,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    String? userId,
    String? email,
    String? name,
    List<String>? roles,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isAdmin: isAdmin ?? this.isAdmin,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      roles: roles ?? this.roles,
    );
  }
}

/// Authentication service using native OIDC with Resource Owner Password Credentials
class AuthService extends Notifier<AuthState> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseService _firebaseService = FirebaseService();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _idTokenKey = 'id_token';

  /// Token endpoint URL
  String get _tokenEndpoint => '${AppConfig.identityUrl}/protocol/openid-connect/token';

  /// Logout endpoint URL
  String get _logoutEndpoint => '${AppConfig.identityUrl}/protocol/openid-connect/logout';

  @override
  AuthState build() => const AuthState();

  /// Initialize auth state from stored tokens
  Future<void> initialize() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshTokenValue = await _storage.read(key: _refreshTokenKey);
      final idToken = await _storage.read(key: _idTokenKey);

      if (accessToken != null && refreshTokenValue != null) {
        // Temporarily set tokens to allow refresh
        state = state.copyWith(
          accessToken: accessToken,
          refreshToken: refreshTokenValue,
          idToken: idToken,
        );

        // Validate tokens by attempting refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          state = state.copyWith(isInitializing: false);
          return;
        }
      }

      // No valid tokens or refresh failed
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: false,
        isAdmin: false,
      );
    } catch (e) {
      debugPrint('Initialize error: $e');
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: false,
        isAdmin: false,
      );
    }
  }

  /// Sign in with username and password using Resource Owner Password Credentials grant
  Future<SignInResult> signIn(String username, String password) async {
    debugPrint('Auth: Attempting sign in for user: $username');
    debugPrint('Auth: Token endpoint: $_tokenEndpoint');
    debugPrint('Auth: Client ID: ${AppConfig.clientId}');

    try {
      final response = await _dio.post(
        _tokenEndpoint,
        data: {
          'grant_type': 'password',
          'client_id': AppConfig.clientId,
          'username': username,
          'password': password,
          'scope': AppConfig.scopes.join(' '),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      debugPrint('Auth: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          idToken: data['id_token'],
        );

        debugPrint('Auth: Tokens saved, isAdmin: ${state.isAdmin}');

        if (!state.isAdmin) {
          await signOut();
          return SignInResult.notAdmin;
        }

        // Auto-register for admin notifications
        await _registerForAdminNotifications();
        await _registerForServiceRequestNotifications();

        return SignInResult.success;
      }
      debugPrint('Auth: Unexpected status code: ${response.statusCode}');
      return SignInResult.failed;
    } on DioException catch (e) {
      debugPrint('Auth: DioException - Status: ${e.response?.statusCode}');
      debugPrint('Auth: DioException - Data: ${e.response?.data}');
      debugPrint('Auth: DioException - Message: ${e.message}');
      return SignInResult.failed;
    } catch (e) {
      debugPrint('Auth: Exception: $e');
      return SignInResult.failed;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Unregister from notifications first
      await _unregisterFromAdminNotifications();
      await _unregisterFromServiceRequestNotifications();

      if (state.refreshToken != null) {
        await _dio.post(
          _logoutEndpoint,
          data: {
            'client_id': AppConfig.clientId,
            'refresh_token': state.refreshToken,
          },
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ),
        );
      }
    } catch (e) {
      // Ignore errors during sign out
    } finally {
      await _clearTokens();
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    if (state.refreshToken == null) return false;

    try {
      final response = await _dio.post(
        _tokenEndpoint,
        data: {
          'grant_type': 'refresh_token',
          'client_id': AppConfig.clientId,
          'refresh_token': state.refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          idToken: data['id_token'],
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('Token refresh error: ${e.response?.data ?? e.message}');
      await _clearTokens();
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await _clearTokens();
      return false;
    }
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return state.accessToken;
  }

  Future<void> _saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (idToken != null) {
      await _storage.write(key: _idTokenKey, value: idToken);
    }

    final claims = _parseJwt(accessToken);
    final roles = _extractRoles(claims);
    final isAdmin = roles.contains(AppConfig.adminRole);

    state = state.copyWith(
      isAuthenticated: true,
      isAdmin: isAdmin,
      accessToken: accessToken,
      refreshToken: refreshToken ?? state.refreshToken,
      idToken: idToken ?? state.idToken,
      userId: claims['sub'] as String?,
      email: claims['email'] as String?,
      name: claims['name'] as String?,
      roles: roles,
    );
  }

  /// Register for admin order notifications
  Future<void> _registerForAdminNotifications() async {
    try {
      // Request notification permission
      final hasPermission = await _firebaseService.requestPermission();
      if (!hasPermission) {
        debugPrint('Notification permission not granted');
        return;
      }

      // Get FCM token
      final fcmToken = await _firebaseService.getToken();
      if (fcmToken == null) {
        debugPrint('Failed to get FCM token');
        return;
      }

      // Register with backend
      final response = await _dio.post(
        '${AppConfig.notificationsApiUrl}subscriptions/admin-orders',
        data: {'fcmToken': fcmToken},
        options: Options(
          headers: {'Authorization': 'Bearer ${state.accessToken}'},
          contentType: Headers.jsonContentType,
        ),
      );

      debugPrint('Admin notification registration: ${response.statusCode == 200 || response.statusCode == 201 ? 'success' : 'failed'}');
    } catch (e) {
      debugPrint('Error registering for admin notifications: $e');
      // Don't fail login if notification registration fails
    }
  }

  /// Unregister from admin order notifications
  Future<void> _unregisterFromAdminNotifications() async {
    if (state.accessToken == null) return;

    try {
      await _dio.delete(
        '${AppConfig.notificationsApiUrl}subscriptions/admin-orders',
        options: Options(
          headers: {'Authorization': 'Bearer ${state.accessToken}'},
        ),
      );
      debugPrint('Unregistered from admin order notifications');
    } catch (e) {
      debugPrint('Error unregistering from admin notifications: $e');
      // Don't fail logout if notification unregistration fails
    }
  }

  /// Register for service request notifications
  Future<void> _registerForServiceRequestNotifications() async {
    try {
      // Request notification permission
      final hasPermission = await _firebaseService.requestPermission();
      if (!hasPermission) {
        debugPrint('Notification permission not granted');
        return;
      }

      // Get FCM token
      final fcmToken = await _firebaseService.getToken();
      if (fcmToken == null) {
        debugPrint('Failed to get FCM token');
        return;
      }

      // Register with backend
      final response = await _dio.post(
        '${AppConfig.notificationsApiUrl}subscriptions/service-requests',
        data: {'fcmToken': fcmToken},
        options: Options(
          headers: {'Authorization': 'Bearer ${state.accessToken}'},
          contentType: Headers.jsonContentType,
        ),
      );

      debugPrint('Service request notification registration: ${response.statusCode == 200 || response.statusCode == 201 ? 'success' : 'failed'}');
    } catch (e) {
      debugPrint('Error registering for service request notifications: $e');
      // Don't fail login if notification registration fails
    }
  }

  /// Unregister from service request notifications
  Future<void> _unregisterFromServiceRequestNotifications() async {
    if (state.accessToken == null) return;

    try {
      await _dio.delete(
        '${AppConfig.notificationsApiUrl}subscriptions/service-requests',
        options: Options(
          headers: {'Authorization': 'Bearer ${state.accessToken}'},
        ),
      );
      debugPrint('Unregistered from service request notifications');
    } catch (e) {
      debugPrint('Error unregistering from service request notifications: $e');
      // Don't fail logout if notification unregistration fails
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _idTokenKey);

    state = const AuthState();
  }

  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  List<String> _extractRoles(Map<String, dynamic> claims) {
    final roles = <String>[];

    debugPrint('Auth: Extracting roles from claims');
    debugPrint('Auth: Claims keys: ${claims.keys.toList()}');

    // Try 'role' claim (flat roles from Keycloak mapper)
    if (claims['role'] != null) {
      debugPrint('Auth: Found "role" claim: ${claims['role']}');
      if (claims['role'] is List) {
        roles.addAll((claims['role'] as List).cast<String>());
      } else if (claims['role'] is String) {
        roles.add(claims['role'] as String);
      }
    }

    // Try 'roles' claim (plural)
    if (claims['roles'] != null) {
      debugPrint('Auth: Found "roles" claim: ${claims['roles']}');
      if (claims['roles'] is List) {
        roles.addAll((claims['roles'] as List).cast<String>());
      } else if (claims['roles'] is String) {
        roles.add(claims['roles'] as String);
      }
    }

    // Try 'realm_access.roles' claim
    if (claims['realm_access'] != null) {
      final realmAccess = claims['realm_access'] as Map<String, dynamic>;
      debugPrint('Auth: Found "realm_access": $realmAccess');
      if (realmAccess['roles'] != null) {
        roles.addAll((realmAccess['roles'] as List).cast<String>());
      }
    }

    final uniqueRoles = roles.toSet().toList();
    debugPrint('Auth: Extracted roles: $uniqueRoles');
    debugPrint('Auth: Looking for admin role: "${AppConfig.adminRole}"');
    debugPrint('Auth: Is admin: ${uniqueRoles.contains(AppConfig.adminRole)}');

    return uniqueRoles;
  }
}

/// Sign in result
enum SignInResult {
  success,
  failed,
  notAdmin,
}

/// Provider for auth service
final authServiceProvider = NotifierProvider<AuthService, AuthState>(AuthService.new);

/// Provider for auth state
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isAuthenticated;
});

/// Provider for admin check
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isAdmin;
});
