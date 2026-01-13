/// Application configuration for Admin Tablet App
class AppConfig {
  // Admin BFF base URL (all API calls go through here)
  // Using localhost works with: adb reverse tcp:27748 tcp:27748
  static String get bffBaseUrl {
    return 'http://localhost:27748';
  }

  // API endpoints (through BFF) - trailing slash required for Dio path resolution
  static String get catalogApiUrl => '$bffBaseUrl/api/catalog/';
  static String get ordersApiUrl => '$bffBaseUrl/api/orders/';
  static String get roomsApiUrl => '$bffBaseUrl/api/rooms/';
  static String get sessionsApiUrl => '$bffBaseUrl/api/sessions/';
  static String get identityApiUrl => '$bffBaseUrl/api/identity/';
  static String get loyaltyApiUrl => '$bffBaseUrl/api/loyalty/';
  static String get notificationsApiUrl => '$bffBaseUrl/api/notifications/';

  // Keycloak configuration (through BFF)
  static String get keycloakUrl => '$bffBaseUrl/auth';
  static const String keycloakRealm = 'chillax';
  static String get identityUrl => '$keycloakUrl/realms/$keycloakRealm';

  // OIDC configuration
  static const String clientId = 'admin-app';
  static const String redirectUri = 'com.chillax.admin://callback';
  static const String postLogoutRedirectUri = 'com.chillax.admin://';
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'roles',
    'orders',
    'rooms',
    'catalog',
  ];

  // Required role for admin access
  static const String adminRole = 'Admin';

  // App info
  static const String appName = 'Chillax Admin';
  static const String appVersion = '1.0.0';

  // Refresh intervals
  static const Duration dashboardRefreshInterval = Duration(seconds: 30);
  static const Duration ordersRefreshInterval = Duration(seconds: 30);
  static const Duration roomsRefreshInterval = Duration(seconds: 10);
}
