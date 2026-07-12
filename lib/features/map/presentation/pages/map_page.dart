import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/logger/index.dart';
import '../../../../core/services/gps_service.dart';
import '../../../../core/storage/preferences/pref_providers.dart';
import '../widgets/map_view.dart';

/// Full-screen map page. Initial camera resolution, 3 tiers:
/// 1. cached location from UserPref (written by LocationSyncService),
/// 2. live GPS fix (moves camera once, drops the my-location dot),
/// 3. fallback: Bogor area.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  static const LatLng fallbackCenter = LatLng(-6.5, 106.8);
  static const double fallbackZoom = 10;
  static const double locatedZoom = 15;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  final GpsService _gpsService = GpsService();

  late LatLng _initialCenter;
  late double _initialZoom;
  LatLng? _myLocation;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialCamera();
    _acquireGpsFix();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _resolveInitialCamera() {
    final pref = ref.read(userPrefProvider);
    final lat = double.tryParse(pref.latitude.get());
    final lng = double.tryParse(pref.longitude.get());
    if (lat != null && lng != null) {
      _initialCenter = LatLng(lat, lng);
      _initialZoom = MapPage.locatedZoom;
    } else {
      _initialCenter = MapPage.fallbackCenter;
      _initialZoom = MapPage.fallbackZoom;
    }
  }

  Future<void> _acquireGpsFix({bool userRequested = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final location = await _gpsService.getCurrentLocation();
      final point = LatLng(location.latitude, location.longitude);
      if (!mounted) return;
      setState(() => _myLocation = point);
      _mapController.move(point, MapPage.locatedZoom);
    } catch (e) {
      log.w('Map GPS fix failed: $e');
      if (mounted && userRequested) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location unavailable: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: MapView(
        controller: _mapController,
        initialCenter: _initialCenter,
        initialZoom: _initialZoom,
        myLocation: _myLocation,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map-recenter',
        tooltip: 'My location',
        onPressed:
            _locating ? null : () => _acquireGpsFix(userRequested: true),
        child: _locating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }
}
