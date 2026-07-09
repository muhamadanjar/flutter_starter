import 'dart:async';

import '../../features/profile/domain/dtos/index.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../logger/index.dart';
import '../storage/preferences/user_pref.dart';
import 'firebase_service.dart';

/// Keeps the device's FCM token registered server-side as the `fcm_token`
/// user meta (POST /auth/metas).
///
/// All failures are silent: push registration must never block auth flows.
class FcmSyncService {
  static const String metaKey = 'fcm_token';

  final FirebaseService _firebaseService;
  final ProfileRepository _profileRepository;
  final UserPref _userPref;
  final Future<bool> Function() _isLoggedIn;

  StreamSubscription<String>? _tokenRefreshSub;

  FcmSyncService({
    required FirebaseService firebaseService,
    required ProfileRepository profileRepository,
    required UserPref userPref,
    required Future<bool> Function() isLoggedIn,
  })  : _firebaseService = firebaseService,
        _profileRepository = profileRepository,
        _userPref = userPref,
        _isLoggedIn = isLoggedIn;

  /// Upsert the current FCM token to auth/metas.
  ///
  /// Skips when not logged in, when no token is available, or when the token
  /// matches the last successfully synced value.
  Future<void> sync() async {
    try {
      if (!await _isLoggedIn()) return;

      final token = await _firebaseService.getToken();
      if (token == null || token.isEmpty) return;
      if (token == _userPref.fcmToken.get()) return;

      final result = await _profileRepository.updateMetas(
        SingleMetaUpdate(key: metaKey, value: token),
      );

      await result.fold(
        (failure) async => log.w('FCM token sync failed: ${failure.message}'),
        (_) async {
          await _userPref.fcmToken.put(token);
          await _userPref.fcmTokenUpdatedAt.put(DateTime.now().millisecondsSinceEpoch);
          log.i('FCM token synced to auth/metas');
        },
      );
    } catch (e) {
      log.w('FCM token sync failed: $e');
    }
  }

  /// Re-sync whenever FCM rotates the token. Idempotent.
  void startTokenRefreshListener() {
    _tokenRefreshSub ??= _firebaseService.onTokenRefresh.listen((_) => sync());
  }

  /// Blank the `fcm_token` meta to detach this device from the account.
  /// Must be called while the session is still valid (i.e. before logout
  /// clears tokens).
  Future<void> detach() async {
    try {
      await _profileRepository.updateMetas(
        const SingleMetaUpdate(key: metaKey, value: ''),
      );
    } catch (e) {
      log.w('FCM token detach failed: $e');
    }
    await _userPref.fcmToken.delete();
    await _userPref.fcmTokenUpdatedAt.put(0);
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
