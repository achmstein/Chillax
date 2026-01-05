/// Application configuration
class AppConfig {
  // API endpoints
  static const String catalogApiUrl = 'https://localhost:5221';
  static const String ordersApiUrl = 'https://localhost:5224';
  static const String roomsApiUrl = 'https://localhost:5250';
  static const String identityUrl = 'https://localhost:5243';

  // OIDC configuration
  static const String clientId = 'chillax-mobile';
  static const String redirectUri = 'com.chillax.app://callback';
  static const String postLogoutRedirectUri = 'com.chillax.app://';
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'orders',
    'rooms',
    'catalog',
  ];

  // App info
  static const String appName = 'Chillax';
  static const String appVersion = '1.0.0';
}
