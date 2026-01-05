import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? userId;
  final String? email;
  final String? name;

  const AuthState({
    this.isAuthenticated = false,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.userId,
    this.email,
    this.name,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    String? userId,
    String? email,
    String? name,
  }) {
    return AuthState(
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

/// Authentication service using OIDC
class AuthService extends StateNotifier<AuthState> {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _idTokenKey = 'id_token';

  AuthService() : super(const AuthState());

  /// Initialize auth state from stored tokens
  Future<void> initialize() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final idToken = await _storage.read(key: _idTokenKey);

    if (accessToken != null) {
      state = state.copyWith(
        isAuthenticated: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
      );
    }
  }

  /// Sign in with OIDC
  Future<bool> signIn() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.clientId,
          AppConfig.redirectUri,
          issuer: AppConfig.identityUrl,
          scopes: AppConfig.scopes,
          promptValues: ['login'],
        ),
      );

      if (result != null) {
        await _saveTokens(result);
        return true;
      }
      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (state.idToken != null) {
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: state.idToken,
            postLogoutRedirectUrl: AppConfig.postLogoutRedirectUri,
            issuer: AppConfig.identityUrl,
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
    if (state.refreshToken == null) return false;

    try {
      final result = await _appAuth.token(
        TokenRequest(
          AppConfig.clientId,
          AppConfig.redirectUri,
          issuer: AppConfig.identityUrl,
          refreshToken: state.refreshToken,
          scopes: AppConfig.scopes,
        ),
      );

      if (result != null) {
        await _saveTokens(result);
        return true;
      }
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

  Future<void> _saveTokens(TokenResponse result) async {
    await _storage.write(key: _accessTokenKey, value: result.accessToken);
    await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
    await _storage.write(key: _idTokenKey, value: result.idToken);

    state = state.copyWith(
      isAuthenticated: true,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _idTokenKey);

    state = const AuthState();
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
