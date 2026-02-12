import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../config/app_config.dart';
import '../services/signalr_service.dart';

/// Supported social login providers
enum SocialProvider { google, apple }

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
/// and native social login SDKs (Google Sign-In, Apple Sign In)
class AuthService extends Notifier<AuthState> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Native social login SDKs
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: AppConfig.googleServerClientId,
  );

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
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      final idToken = await _storage.read(key: _idTokenKey);

      debugPrint('Auth init - has access token: ${accessToken != null}');
      debugPrint('Auth init - has refresh token: ${refreshToken != null}');

      if (accessToken != null && refreshToken != null) {
        // Try to refresh the token to validate it's still valid
        state = state.copyWith(
          accessToken: accessToken,
          refreshToken: refreshToken,
          idToken: idToken,
        );

        final refreshed = await this.refreshToken();
        debugPrint('Auth init - token refresh result: $refreshed');
        if (refreshed) {
          state = state.copyWith(
            isInitializing: false,
            isAuthenticated: true,
          );
          return;
        }
      }

      // No valid tokens found
      debugPrint('Auth init - no valid tokens, user needs to login');
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: false,
      );
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: false,
      );
    }
  }

  /// Sign in with username and password using Resource Owner Password Credentials grant
  Future<bool> signIn(String username, String password) async {
    debugPrint('Attempting sign in to: $_tokenEndpoint');
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

      debugPrint('Sign in response status: ${response.statusCode}');
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
      debugPrint('Sign in DioException: ${e.type} - ${e.message}');
      debugPrint('Sign in error response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  /// Generate a random nonce string for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash of a string (used for Apple Sign In nonce on Android)
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with social provider using native SDKs (no browser)
  Future<bool> signInWithProvider(SocialProvider provider) async {
    debugPrint('Attempting native social sign in with: ${provider.name}');

    try {
      String? socialToken;
      String providerAlias;
      String tokenType;

      if (provider == SocialProvider.google) {
        // Use native Google Sign-In
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint('Google sign in cancelled by user');
          return false;
        }

        final googleAuth = await googleUser.authentication;
        socialToken = googleAuth.accessToken;
        providerAlias = 'google';
        tokenType = 'urn:ietf:params:oauth:token-type:access_token';
        debugPrint('Google sign in successful, got access token');
      } else {
        // Use Sign In with Apple
        final rawNonce = _generateNonce();
        final hashedNonce = _sha256ofString(rawNonce);

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        socialToken = credential.identityToken;
        providerAlias = 'apple';
        tokenType = 'urn:ietf:params:oauth:token-type:id_token';
        debugPrint('Apple sign in successful, got identity token');
      }

      if (socialToken == null) {
        debugPrint('No social token received');
        return false;
      }

      // Exchange social token with Keycloak using token exchange grant
      return await _exchangeSocialToken(socialToken, providerAlias, tokenType);
    } catch (e) {
      debugPrint('Social sign in error: $e');
      return false;
    }
  }

  /// Exchange social provider token for Keycloak tokens
  Future<bool> _exchangeSocialToken(String socialToken, String providerAlias, String tokenType) async {
    debugPrint('Exchanging $providerAlias token with Keycloak');

    try {
      final response = await _dio.post(
        _tokenEndpoint,
        data: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'client_id': AppConfig.clientId,
          'subject_token': socialToken,
          'subject_token_type': tokenType,
          'subject_issuer': providerAlias,
          'scope': AppConfig.scopes.join(' '),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      debugPrint('Token exchange response status: ${response.statusCode}');
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
      debugPrint('Token exchange DioException: ${e.type} - ${e.message}');
      debugPrint('Token exchange error response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Token exchange error: $e');
      return false;
    }
  }

  /// Register a new user
  Future<bool> register(String name, String email, String phone, String password) async {
    try {
      // Call the BFF registration endpoint which handles Keycloak user creation
      final response = await _dio.post(
        '${AppConfig.bffBaseUrl}/api/identity/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('Registration error: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Disconnect SignalR
      await ref.read(signalRServiceProvider).disconnect();

      // Sign out from Keycloak
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

      // Sign out from social providers
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      await _clearTokens();
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    if (state.refreshToken == null) {
      debugPrint('Token refresh - no refresh token available');
      return false;
    }

    try {
      debugPrint('Token refresh - calling $_tokenEndpoint');
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
        debugPrint('Token refresh - success');
        return true;
      }
      debugPrint('Token refresh - failed with status ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      debugPrint('Token refresh DioException: ${e.type}');
      debugPrint('Token refresh error response: ${e.response?.statusCode} - ${e.response?.data}');
      debugPrint('Token refresh error message: ${e.message}');
      // Only clear tokens if the server explicitly rejected the refresh token
      // (400 = invalid_grant / expired). Don't clear on network errors or timeouts.
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        await _clearTokens();
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return state.accessToken;
  }

  /// Decode JWT token payload (without verification - just for reading claims)
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
      return null;
    }
  }

  Future<void> _saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    debugPrint('Saving tokens to secure storage...');
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (idToken != null) {
      await _storage.write(key: _idTokenKey, value: idToken);
    }
    debugPrint('Tokens saved successfully');

    // Extract user info from token
    String? userId;
    String? email;
    String? name;

    // Try to decode id_token first (has user info), fallback to access_token
    final tokenToDecode = idToken ?? accessToken;
    final claims = _decodeJwtPayload(tokenToDecode);
    if (claims != null) {
      userId = claims['sub'] as String?;
      email = claims['email'] as String?;
      // Keycloak: 'name' is full name (firstName + lastName), 'preferred_username' is username
      name = claims['name'] as String? ?? claims['preferred_username'] as String?;
      debugPrint('Extracted user info - userId: $userId, email: $email, name: $name');
    }

    state = state.copyWith(
      isAuthenticated: true,
      accessToken: accessToken,
      refreshToken: refreshToken ?? state.refreshToken,
      idToken: idToken ?? state.idToken,
      userId: userId,
      email: email,
      name: name,
    );

    // Connect SignalR for realtime updates
    ref.read(signalRServiceProvider).connect();
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _idTokenKey);

    state = const AuthState(isInitializing: false);
  }
}

/// Provider for auth service
final authServiceProvider = NotifierProvider<AuthService, AuthState>(AuthService.new);

/// Provider for auth state
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isAuthenticated;
});
