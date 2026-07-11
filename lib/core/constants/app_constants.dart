class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Enterprise App';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String isLoggedInKey = 'is_logged_in';
  static const String userProfileKey = 'user_profile';
  static const String appSettingsKey = 'app_settings';
  static const String lastSyncKey = 'last_sync';

  // Hive Box Names
  static const String authBox = 'auth_box';
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  // Date Format
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd MMM yyyy HH:mm';

  // Pagination
  static const int defaultPageSize = 20;

  // Password
  static const int minPasswordLength = 8;
}
