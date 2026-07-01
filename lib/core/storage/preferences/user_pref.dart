import 'pref.dart';
import 'pref_group.dart';

/// User preferences storage (auth, theme, language, etc.)
class UserPref extends PrefGroup {
  @override
  String get boxName => 'user_preferences';

  // Auth preferences
  late final Pref<String> userId = pref<String>('user_id', '');
  late final Pref<String> username = pref<String>('username', '');
  late final Pref<String?> email = pref<String?>('email', null);
  late final Pref<String?> accessToken = pref<String?>('access_token', null);
  late final Pref<String?> refreshToken = pref<String?>('refresh_token', null);
  late final Pref<bool> isLoggedIn = pref<bool>('is_logged_in', false);
  late final Pref<int> loginTimestamp = pref<int>('login_timestamp', 0);

  // UI preferences
  late final Pref<bool> darkMode = pref<bool>('dark_mode', true);
  late final Pref<String> locale = pref<String>('locale', 'en');
  late final Pref<String> fontSize = pref<String>('font_size', 'medium');

  // Feature preferences
  late final Pref<bool> notificationsEnabled = pref<bool>('notifications_enabled', true);
  late final Pref<bool> biometricEnabled = pref<bool>('biometric_enabled', false);
  late final Pref<bool> autoSync = pref<bool>('auto_sync', true);
  late final Pref<bool> analyticsEnabled = pref<bool>('analytics_enabled', true);

  // FCM preferences
  late final Pref<String?> fcmToken = pref<String?>('fcm_token', null);
  late final Pref<int> fcmTokenUpdatedAt = pref<int>('fcm_token_updated_at', 0);

  // GPS/Location preferences
  late final Pref<String> latitude = pref<String>('latitude', '');
  late final Pref<String> longitude = pref<String>('longitude', '');
  late final Pref<int> locationTimestamp = pref<int>('location_timestamp', 0);

  /// Clear auth data (logout)
  Future<void> clearAuth() async {
    await userId.delete();
    await username.delete();
    await email.delete();
    await accessToken.delete();
    await refreshToken.delete();
    await isLoggedIn.put(false);
    await loginTimestamp.put(0);
  }

  /// Clear all user data (app reset)
  Future<void> clearAll() async {
    await clear();
  }
}
