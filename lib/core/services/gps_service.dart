import 'package:geolocator/geolocator.dart';
import '../logger/index.dart';

class LocationData {

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  factory LocationData.fromPosition(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      timestamp: position.timestamp,
    );
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'altitude': altitude,
    'speed': speed,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
}

class GpsService {

  factory GpsService() {
    return _instance;
  }

  GpsService._internal();
  static final GpsService _instance = GpsService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      log.e('Error checking location service', e);
      return false;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      log.d('Location permission: $permission');
      return permission;
    } catch (e) {
      log.e('Error requesting location permission', e);
      rethrow;
    }
  }

  /// Check current location permission
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      log.e('Error checking location permission', e);
      rethrow;
    }
  }

  /// Get current location
  Future<LocationData> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    try {
      // Check if service enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        throw LocationServiceDisabledException(
          'Location services are disabled. Enable them in settings.',
        );
      }

      // Check permission, request it via the OS dialog if not yet granted
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw PermissionException(
          'Location permission denied.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw PermissionException(
          'Location permission permanently denied. Grant permission in app settings.',
        );
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 30),
      );

      final location = LocationData.fromPosition(position);
      log.d('Current location: $location');
      return location;
    } on LocationServiceDisabledException catch (e) {
      log.e('Location service disabled', e);
      rethrow;
    } on PermissionException catch (e) {
      log.e('Permission denied', e);
      rethrow;
    } catch (e) {
      log.e('Error getting current location', e);
      rethrow;
    }
  }

  /// Stream continuous location updates
  Stream<LocationData> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map((position) {
      final location = LocationData.fromPosition(position);
      log.d('Location update: $location');
      return location;
    }).handleError((error) {
      log.e('Error in location stream', error);
    });
  }

  /// Calculate distance between two points (in meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Open app location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      log.e('Error opening location settings', e);
      return false;
    }
  }

  /// Open app permission settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      log.e('Error opening app settings', e);
      return false;
    }
  }
}

class LocationServiceDisabledException implements Exception {

  LocationServiceDisabledException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PermissionException implements Exception {

  PermissionException(this.message);
  final String message;

  @override
  String toString() => message;
}
