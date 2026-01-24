/// Application configuration
class AppConfig {
  // Mobile BFF base URL (all API calls go through here)
  // With adb reverse, use localhost; for emulator use 10.0.2.2
  static String get bffBaseUrl {
    // Using localhost works with: adb reverse tcp:27748 tcp:27748
    return 'http://localhost:27748';
  }

  // API endpoints (through BFF) - trailing slash required for Dio path resolution
  static String get catalogApiUrl => '$bffBaseUrl/api/catalog/';
  static String get ordersApiUrl => '$bffBaseUrl/api/orders/';
  static String get roomsApiUrl => '$bffBaseUrl/api/rooms/';
  static String get sessionsApiUrl => '$bffBaseUrl/api/sessions/';
  static String get loyaltyApiUrl => '$bffBaseUrl/api/loyalty/';
  static String get notificationsApiUrl => '$bffBaseUrl/api/notifications/';
  static String get accountsApiUrl => '$bffBaseUrl/api/accounts/';

  // Keycloak configuration (through BFF)
  static String get keycloakUrl => '$bffBaseUrl/auth';
  static const String keycloakRealm = 'chillax';
  static String get identityUrl => '$keycloakUrl/realms/$keycloakRealm';

  // OIDC configuration
  static const String clientId = 'mobile-app';
  static const String redirectUri = 'com.chillax.app://callback';
  static const String postLogoutRedirectUri = 'com.chillax.app://';
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
