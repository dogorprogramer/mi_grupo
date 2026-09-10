class AppConstants {
  AppConstants._();

  static const String appName = 'MiGrupo';
  static const String baseUrl = 'https://dummyjson.com';

  static const String authTokenKey = 'auth_token';
  static const String favoritesKey = 'favorite_products';
  static const String themeModeKey = 'theme_mode';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}
