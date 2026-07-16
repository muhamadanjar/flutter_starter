import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/track_record.dart';
import '../models/track_record_model.dart';

/// Local persistence (Hive) for track records.
///
/// Stores the whole collection as a single JSON string under one key in the
/// `record_tracks` box, mirroring how other local collections are kept atomic
/// in this project. The box itself is opened in `main_common.dart` (or lazily
/// via [openBox]) so it is available everywhere after startup.
abstract class TrackRecordLocalDataSource {
  Future<void> openBox();
  Future<List<TrackRecord>> getAll();
  Future<TrackRecord?> getById(String id);
  Future<String> startTrack({required String name, String note = ''});
  Future<void> addPoint(
    String trackId, {
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    double speed = 0.0,
    double accuracy = 0.0,
    DateTime? timestamp,
  });
  Future<void> saveTrack(TrackRecord track);
  Future<void> deleteTrack(String trackId);
  Future<void> clear();
}

class TrackRecordLocalDataSourceImpl implements TrackRecordLocalDataSource {
  TrackRecordLocalDataSourceImpl({this.boxName = 'record_tracks'});

  final String boxName;
  Box? _box;

  Box get _store {
    final cached = _box;
    if (cached != null && cached.isOpen) return cached;
    if (Hive.isBoxOpen(boxName)) return _box = Hive.box(boxName);
    throw StateError(
      'Hive box "$boxName" is not open. Call openBox() during app startup.',
    );
  }

  @override
  Future<void> openBox() async {
    _box = await Hive.openBox(boxName);
  }

  List<TrackRecordModel> _readAll() {
    final raw = _store.get(_tracksKey) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TrackRecordModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeAll(List<TrackRecordModel> tracks) async {
    await _store.put(_tracksKey, jsonEncode(tracks.map((t) => t.toJson()).toList()));
  }

  @override
  Future<List<TrackRecord>> getAll() async {
    final tracks = _readAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tracks.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TrackRecord?> getById(String id) async {
    for (final m in _readAll()) {
      if (m.id == id) return m.toEntity();
    }
    return null;
  }

  @override
  Future<String> startTrack({required String name, String note = ''}) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    final track = TrackRecordModel(
      id: id,
      name: name,
      note: note,
      createdAt: DateTime.now(),
      points: const [],
    );
    final tracks = _readAll()..add(track);
    await _writeAll(tracks);
    return id;
  }

  @override
  Future<void> addPoint(
    String trackId, {
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    double speed = 0.0,
    double accuracy = 0.0,
    DateTime? timestamp,
  }) async {
    final tracks = List<TrackRecordModel>.from(_readAll());
    final idx = tracks.indexWhere((t) => t.id == trackId);
    if (idx == -1) return;

    final point = TrackPointModel(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speed: speed,
      accuracy: accuracy,
      timestamp: timestamp ?? DateTime.now(),
    );
    final updated = tracks[idx].copyWith(
      updatedAt: DateTime.now(),
      points: [...tracks[idx].points, point],
    ) as TrackRecordModel;
    tracks[idx] = updated;
    await _writeAll(tracks);
  }

  @override
  Future<void> saveTrack(TrackRecord track) async {
    final model = TrackRecordModel.fromEntity(track);
    final tracks = List<TrackRecordModel>.from(_readAll());
    final idx = tracks.indexWhere((t) => t.id == model.id);
    if (idx == -1) {
      tracks.add(model);
    } else {
      tracks[idx] = model;
    }
    await _writeAll(tracks);
  }

  @override
  Future<void> deleteTrack(String trackId) async {
    final tracks = _readAll()..removeWhere((t) => t.id == trackId);
    await _writeAll(tracks);
  }

  @override
  Future<void> clear() async {
    await _store.delete(_tracksKey);
  }

  static const String _tracksKey = 'tracks';
}
