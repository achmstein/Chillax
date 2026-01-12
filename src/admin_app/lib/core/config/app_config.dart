import 'dart:io' show Platform;

/// Application configuration for Admin Tablet App
class AppConfig {
  // Admin BFF base URL (all API calls go through here)
  // Use 10.0.2.2 for Android emulator to reach host machine
  static String get bffBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:27749';
    }
    return 'http://localhost:27749';
  }

  // API endpoints (through BFF)
  static String get catalogApiUrl => '$bffBaseUrl/api/catalog';
  static String get ordersApiUrl => '$bffBaseUrl/api/orders';
  static String get roomsApiUrl => '$bffBaseUrl/api/rooms';
  static String get basketApiUrl => '$bffBaseUrl/api/basket';
  static String get sessionsApiUrl => '$bffBaseUrl/api/sessions';
  static String get usersApiUrl => '$bffBaseUrl/api/identity';
  static String get loyaltyApiUrl => '$bffBaseUrl/api/loyalty';
  static String get notificationsApiUrl => '$bffBaseUrl/api/notifications';

  // Keycloak configuration (through BFF)
  static String get keycloakUrl => '$bffBaseUrl/auth';
  static const String keycloakRealm = 'chillax';
  static String get identityUrl => '$keycloakUrl/realms/$keycloakRealm';

  // OIDC configuration
  static const String clientId = 'chillax-admin-tablet';
  static const String redirectUri = 'com.chillax.admin://callback';
  static const String postLogoutRedirectUri = 'com.chillax.admin://';
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'roles',
    'offline_access',
    'orders',
    'rooms',
    'catalog',
    'basket',
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
