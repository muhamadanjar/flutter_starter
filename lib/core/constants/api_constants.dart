class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.example.com/v1';
  static const String login = '/auth/login';
  static const String logout = '/logout';
  static const String register = '/auth/register';
  static const String profile = '/auth/info';
  static const String updateProfile = '/auth/profile';
  static const String uploadAvatar = '/auth/update-avatar';
  static const String changePassword = '/auth/change-password';
  static const String refreshToken = '/auth/refresh';
  static const String authMetas = '/auth/metas';
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';

  static Duration connectTimeout = const Duration(seconds: 30);
  static Duration receiveTimeout = const Duration(seconds: 30);
  static Duration sendTimeout = const Duration(seconds: 30);
}
