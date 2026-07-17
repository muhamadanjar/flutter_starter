import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logger/index.dart';
import '../../../../core/services/gps_service.dart';
import '../../domain/entities/track_record.dart';
import '../providers/map_providers.dart';

/// Floating action button that starts/stops a GPS track recording session.
///
/// While recording it streams location updates from GpsService and appends
/// each sample to the active track via AddTrackPointUseCase. The live route
/// is pushed back through onPointsChanged so the map can draw it.
class TrackRecordFab extends ConsumerStatefulWidget {
  const TrackRecordFab({required this.onPointsChanged, super.key});
  final void Function(List<TrackPoint> points) onPointsChanged;

  @override
  ConsumerState<TrackRecordFab> createState() => _TrackRecordFabState();
}

class _TrackRecordFabState extends ConsumerState<TrackRecordFab> {
  final GpsService _gps = GpsService();
  Stream<LocationData>? _stream;
  List<TrackPoint> _points = const [];
  bool _busy = false;

  String? get _activeId => ref.read(activeTrackIdProvider);
  bool get _recording => _activeId != null;

  Future<void> _toggle() async {
    if (_recording) return _stop();
    await _start();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final name =
          'Track ${DateTime.now().toString().replaceFirst(' ', ' · ').substring(0, 16)}';
      final idResult = await ref.read(startTrackUseCaseProvider)(
        name: name,
      );
      final id = idResult.fold(
        (f) => throw Exception(f.message),
        (id) => id,
      );

      _points = const [];
      widget.onPointsChanged(_points);
      ref.read(activeTrackIdProvider.notifier).state = id;

      _stream = _gps.getLocationStream(distanceFilter: 5);
      _stream!.listen((loc) => _onPoint(loc));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onPoint(LocationData loc) async {
    final id = _activeId;
    if (id == null) return;
    final result = await ref.read(addTrackPointUseCaseProvider)(
      id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      altitude: loc.altitude ?? 0,
      speed: loc.speed ?? 0,
      accuracy: loc.accuracy ?? 0,
      timestamp: loc.timestamp,
    );
    result.fold(
      (f) => log.w('addPoint failed: ${f.message}'),
      (_) {
        _points = [..._points, _toPoint(loc)];
        widget.onPointsChanged(_points);
      },
    );
  }

  Future<void> _stop() async {
    ref.read(activeTrackIdProvider.notifier).state = null;
    _stream = null;
    _points = const [];
    widget.onPointsChanged(_points);
    ref.invalidate(trackRecordsProvider);
    if (mounted) setState(() {});
  }

  TrackPoint _toPoint(LocationData loc) => TrackPoint(
        latitude: loc.latitude,
        longitude: loc.longitude,
        altitude: loc.altitude ?? 0,
        speed: loc.speed ?? 0,
        accuracy: loc.accuracy ?? 0,
        timestamp: loc.timestamp,
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      heroTag: 'track-record',
      tooltip: _recording ? 'Stop recording' : 'Start recording',
      backgroundColor: _recording ? Colors.red : colorScheme.primary,
      onPressed: _busy ? null : _toggle,
      child: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
    );
  }
}
