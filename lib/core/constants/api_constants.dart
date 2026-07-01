class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.example.com/v1';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/info';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/user/change-password';
  static const String dashboard = '/dashboard';
  static const String refreshToken = '/auth/refresh';
  static const String authMetas = '/auth/metas';

  static Duration connectTimeout = const Duration(seconds: 30);
  static Duration receiveTimeout = const Duration(seconds: 30);
  static Duration sendTimeout = const Duration(seconds: 30);
}
