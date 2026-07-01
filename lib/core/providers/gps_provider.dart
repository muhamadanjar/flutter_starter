import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../logger/index.dart';
import '../services/gps_service.dart';
import '../storage/preferences/index.dart';
import '../../features/profile/domain/dtos/index.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/datasources/profile_local_datasource.dart';
import '../network/network_info.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

/// GPS service singleton
final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});

/// Get current location once
final currentLocationProvider = FutureProvider<LocationData>((ref) async {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.getCurrentLocation();
});

/// Stream continuous location updates
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.getLocationStream();
});

/// Check location permission
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.checkPermission();
});

/// Save location to user preferences and sync to auth/metas
final saveLocationProvider = FutureProvider.family<void, LocationData>((ref, location) async {
  final userPref = ref.watch(userPrefProvider);

  // Save to local preferences
  await userPref.latitude.put(location.latitude.toString());
  await userPref.longitude.put(location.longitude.toString());
  await userPref.locationTimestamp.put(location.timestamp.millisecondsSinceEpoch);

  // Sync to server via auth/metas (PUT bulk update)
  try {
    // Get profile notifier to sync location
    final profileNotifier = ref.read(profileProvider.notifier);

    // Update user metadata with location
    await profileNotifier.updateLocationMetas(location);

    log.i('Location synced to server: ${location.latitude}, ${location.longitude}');
  } catch (e) {
    log.w('Failed to sync location to server: $e');
    // Continue even if sync fails - location is saved locally
  }
});

/// Get last saved location
final lastLocationProvider = FutureProvider<LocationData?>((ref) async {
  final userPref = ref.watch(userPrefProvider);

  final latStr = userPref.latitude.get();
  final lngStr = userPref.longitude.get();
  final timestamp = userPref.locationTimestamp.get();

  if (latStr.isEmpty || lngStr.isEmpty || timestamp == 0) {
    return null;
  }

  return LocationData(
    latitude: double.parse(latStr),
    longitude: double.parse(lngStr),
    timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
  );
});

/// Notifier for managing location tracking state
class LocationTrackingNotifier extends StateNotifier<bool> {
  final GpsService _gpsService;
  final Ref _ref;

  LocationTrackingNotifier(this._gpsService, this._ref) : super(false);

  Future<void> startTracking() async {
    state = true;
    _gpsService.getLocationStream().listen((location) {
      // Save to preferences on each update
      _ref.read(saveLocationProvider(location));
    });
  }

  Future<void> stopTracking() async {
    state = false;
  }
}

/// Location tracking state provider
final locationTrackingProvider = StateNotifierProvider<LocationTrackingNotifier, bool>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return LocationTrackingNotifier(gpsService, ref);
});
