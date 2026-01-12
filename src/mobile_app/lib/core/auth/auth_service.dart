import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// Authentication state
class AuthState {
  final bool isInitializing;
  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? userId;
  final String? email;
  final String? name;

  const AuthState({
    this.isInitializing = true,
    this.isAuthenticated = false,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.userId,
    this.email,
    this.name,
  });

  AuthState copyWith({
    bool? isInitializing,
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    String? userId,
    String? email,
    String? name,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }
}

/// Authentication service using native OIDC with Resource Owner Password Credentials
class AuthService extends StateNotifier<AuthState> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _idTokenKey = 'id_token';

  /// Token endpoint URL
  String get _tokenEndpoint => '${AppConfig.identityUrl}/protocol/openid-connect/token';

  /// Logout endpoint URL
  String get _logoutEndpoint => '${AppConfig.identityUrl}/protocol/openid-connect/logout';

  AuthService() : super(const AuthState());

  /// Initialize auth state from stored tokens
  Future<void> initialize() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      final idToken = await _storage.read(key: _idTokenKey);

      print('Auth init - has access token: ${accessToken != null}');
      print('Auth init - has refresh token: ${refreshToken != null}');

      if (accessToken != null && refreshToken != null) {
        // Try to refresh the token to validate it's still valid
        state = state.copyWith(
          accessToken: accessToken,
          refreshToken: refreshToken,
          idToken: idToken,
        );

        final refreshed = await this.refreshToken();
        print('Auth init - token refresh result: $refreshed');
        if (refreshed) {
          state = state.copyWith(
            isInitializing: false,
            isAuthenticated: true,
          );
          return;
        }
      }

      // No valid tokens found
      print('Auth init - no valid tokens, user needs to login');
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: false,
      );
    } catch (e) {
      print('Auth initialization error: $e');
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: false,
      );
    }
  }

  /// Sign in with username and password using Resource Owner Password Credentials grant
  Future<bool> signIn(String username, String password) async {
    print('Attempting sign in to: $_tokenEndpoint');
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

      print('Sign in response status: ${response.statusCode}');
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
      print('Sign in DioException: ${e.type} - ${e.message}');
      print('Sign in error response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  /// Register a new user
  Future<bool> register(String username, String email, String password) async {
    try {
      // Call the BFF registration endpoint which handles Keycloak user creation
      final response = await _dio.post(
        '${AppConfig.bffBaseUrl}/api/identity/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Registration error: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
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
      print('Sign out error: $e');
    } finally {
      await _clearTokens();
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    if (state.refreshToken == null) {
      print('Token refresh - no refresh token available');
      return false;
    }

    try {
      print('Token refresh - calling $_tokenEndpoint');
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
        print('Token refresh - success');
        return true;
      }
      print('Token refresh - failed with status ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      print('Token refresh DioException: ${e.type}');
      print('Token refresh error response: ${e.response?.statusCode} - ${e.response?.data}');
      print('Token refresh error message: ${e.message}');
      await _clearTokens();
      return false;
    } catch (e) {
      print('Token refresh error: $e');
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
    print('Saving tokens to secure storage...');
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (idToken != null) {
      await _storage.write(key: _idTokenKey, value: idToken);
    }
    print('Tokens saved successfully');

    state = state.copyWith(
      isAuthenticated: true,
      accessToken: accessToken,
      refreshToken: refreshToken ?? state.refreshToken,
      idToken: idToken ?? state.idToken,
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _idTokenKey);

    state = const AuthState(isInitializing: false);
  }
}

/// Provider for auth service
final authServiceProvider = StateNotifierProvider<AuthService, AuthState>((ref) {
  return AuthService();
});

/// Provider for auth state
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isAuthenticated;
});
