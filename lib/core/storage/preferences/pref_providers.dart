import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_pref.dart';

/// Singleton UserPref instance
final userPrefProvider = Provider<UserPref>((ref) {
  return UserPref();
});

/// Initialize user preferences (run in main)
final initUserPrefProvider = FutureProvider<UserPref>((ref) async {
  final userPref = ref.watch(userPrefProvider);
  await userPref.initBox();
  return userPref;
});

// Auth streams
final userIdStreamProvider = StreamProvider<String>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.userId.stream();
});

final usernameStreamProvider = StreamProvider<String>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.username.stream();
});

final accessTokenStreamProvider = StreamProvider<String?>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.accessToken.stream();
});

final isLoggedInStreamProvider = StreamProvider<bool>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.isLoggedIn.stream();
});

// UI streams
final darkModeStreamProvider = StreamProvider<bool>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.darkMode.stream();
});

final localeStreamProvider = StreamProvider<String>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.locale.stream();
});

final fontSizeStreamProvider = StreamProvider<String>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.fontSize.stream();
});

// Feature streams
final notificationsEnabledStreamProvider = StreamProvider<bool>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.notificationsEnabled.stream();
});

final biometricEnabledStreamProvider = StreamProvider<bool>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.biometricEnabled.stream();
});

final fcmTokenStreamProvider = StreamProvider<String?>((ref) {
  final userPref = ref.watch(userPrefProvider);
  return userPref.fcmToken.stream();
});
