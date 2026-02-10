/// Application configuration
class AppConfig {
  // Mobile BFF base URL (all API calls go through here)
  // Debug: localhost with adb reverse tcp:8080 tcp:80
  // Release: Oracle Cloud server
  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');
  static String get bffBaseUrl {
    return _isRelease
        ? 'http://145.241.109.212'
        : 'http://localhost:8080';
  }

  // API endpoints (through BFF) - trailing slash required for Dio path resolution
  static String get catalogApiUrl => '$bffBaseUrl/api/catalog/';
  static String get ordersApiUrl => '$bffBaseUrl/api/orders/';
  static String get roomsApiUrl => '$bffBaseUrl/api/rooms/';
  static String get sessionsApiUrl => '$bffBaseUrl/api/sessions/';
  static String get loyaltyApiUrl => '$bffBaseUrl/api/loyalty/';
  static String get notificationsApiUrl => '$bffBaseUrl/api/notifications/';
  static String get accountsApiUrl => '$bffBaseUrl/api/accounts/';
  static String get identityApiUrl => '$bffBaseUrl/api/identity/';

  // Keycloak configuration (through BFF)
  static String get keycloakUrl => '$bffBaseUrl/auth';
  static const String keycloakRealm = 'chillax';
  static String get identityUrl => '$keycloakUrl/realms/$keycloakRealm';

  // OIDC configuration
  static const String clientId = 'mobile-app';
  static const String redirectUri = 'com.chillax.client://callback';
  static const String postLogoutRedirectUri = 'com.chillax.client://';

  // Social login configuration
  // Google: This should match the Web Client ID configured in Keycloak
  // Set via environment or replace with actual value from Google Cloud Console
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: 'your-google-web-client-id.apps.googleusercontent.com',
  );

  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'roles',
    'offline_access',
    'orders',
    'rooms',
    'catalog',
  ];

  // App info
  static const String appName = 'Chillax';
  static const String appVersion = '1.0.0';
}
