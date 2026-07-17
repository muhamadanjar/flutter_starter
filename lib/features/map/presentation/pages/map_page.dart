import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/logger/index.dart';
import '../../../../core/services/gps_service.dart';
import '../../../../core/storage/preferences/pref_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/track_record.dart';
import '../providers/map_providers.dart';
import '../widgets/map_view.dart';
import '../widgets/track_list_sheet.dart';
import '../widgets/track_record_fab.dart';

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
  final TextEditingController _searchController = TextEditingController();

  late LatLng _initialCenter;
  late double _initialZoom;
  LatLng? _myLocation;
  bool _locating = false;
  bool _searching = false;
  List<TrackPoint> _trackPoints = const [];

  @override
  void initState() {
    super.initState();
    _resolveInitialCamera();
    _acquireGpsFix();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
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

  void _openSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final recording = ref.watch(activeTrackIdProvider) != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.colors.surface,
        title: _searching
            ? _SearchField(controller: _searchController)
            : Text(
                'Map',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: 'Search',
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.route_outlined),
            tooltip: 'Track records',
            onPressed: () => showTrackListSheet(
              context,
              onSelected: (track) => setState(() => _trackPoints = track.points),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MapView(
            controller: _mapController,
            initialCenter: _initialCenter,
            initialZoom: _initialZoom,
            myLocation: _myLocation,
            trackPoints: _trackPoints,
          ),

          // Top status chips — minimal, non-intrusive.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recording) const _RecordingChip(),
                    if (_myLocation == null)
                      _StatusChip(
                        icon: Icons.location_off_outlined,
                        label: 'Locating…',
                        color: context.colors.warning,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _MapFabCluster(
        locating: _locating,
        onRecenter: () => _acquireGpsFix(userRequested: true),
        onPointsChanged: (pts) => setState(() => _trackPoints = pts),
      ),
    );
  }
}

/// Inline search field used in the app bar.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search places…',
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: context.colors.textHint),
        border: InputBorder.none,
        isCollapsed: true,
      ),
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: context.colors.textPrimary),
    );
  }
}

/// Pulsing "Recording" chip shown while a GPS track is active.
class _RecordingChip extends StatelessWidget {
  const _RecordingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: context.colors.error),
          const SizedBox(width: 8),
          Text(
            'Recording',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.colors.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Generic status chip for transient map states.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Small pulsing dot used inside the recording chip.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);
  late final Animation<double> _animation =
      Tween<double>(begin: 0.4, end: 1).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Right-aligned FAB cluster: prominent record button on top,
/// recenter button below. Layers & zoom live inside MapView.
class _MapFabCluster extends StatelessWidget {
  const _MapFabCluster({
    required this.locating,
    required this.onRecenter,
    required this.onPointsChanged,
  });
  final bool locating;
  final VoidCallback onRecenter;
  final void Function(List<TrackPoint> points) onPointsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TrackRecordFab(onPointsChanged: onPointsChanged),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'map-recenter',
          tooltip: 'My location',
          onPressed: locating ? null : onRecenter,
          child: locating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
