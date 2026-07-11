import '../../features/profile/domain/dtos/index.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../logger/index.dart';
import '../storage/preferences/user_pref.dart';
import 'gps_service.dart';

/// Keeps the device's last known location registered server-side as the
/// `latitude` / `longitude` user metas (POST /auth/metas).
///
/// All failures are silent: location registration must never block auth
/// flows (permission denied, GPS off, timeout, etc).
class LocationSyncService {

  LocationSyncService({
    required GpsService gpsService,
    required ProfileRepository profileRepository,
    required UserPref userPref,
    required Future<bool> Function() isLoggedIn,
  })  : _gpsService = gpsService,
        _profileRepository = profileRepository,
        _userPref = userPref,
        _isLoggedIn = isLoggedIn;
  static const String latitudeKey = 'latitude';
  static const String longitudeKey = 'longitude';
  static const String timestampKey = 'location_timestamp';
  static const String accuracyKey = 'location_accuracy';

  final GpsService _gpsService;
  final ProfileRepository _profileRepository;
  final UserPref _userPref;
  final Future<bool> Function() _isLoggedIn;

  /// Upsert the current device location to auth/metas.
  ///
  /// Skips when not logged in. Permission/GPS errors are logged and
  /// swallowed.
  Future<void> sync() async {
    try {
      if (!await _isLoggedIn()) return;

      final location = await _gpsService.getCurrentLocation();
      log.i('[GPS][LOCATION] ${location.latitude}, ${location.longitude}');

      final result = await _profileRepository.updateMetas(
        BulkMetaUpdate(items: [
          MetaItem(key: latitudeKey, value: location.latitude.toString()),
          MetaItem(key: longitudeKey, value: location.longitude.toString()),
          MetaItem(key: timestampKey, value: location.timestamp.toIso8601String()),
          MetaItem(key: accuracyKey, value: location.accuracy?.toString() ?? ''),
        ]),
      );

      await result.fold(
        (failure) async => log.w('Location sync failed: ${failure.message}'),
        (_) async {
          await _userPref.latitude.put(location.latitude.toString());
          await _userPref.longitude.put(location.longitude.toString());
          await _userPref.locationTimestamp
              .put(location.timestamp.millisecondsSinceEpoch);
          log.i('Location synced to auth/metas');
        },
      );
    } catch (e) {
      log.w('Location sync failed: $e');
    }
  }
}
