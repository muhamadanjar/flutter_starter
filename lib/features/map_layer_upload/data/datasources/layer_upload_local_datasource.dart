import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/layer_upload_model.dart';

/// Local persistence (Hive) for chunked layer uploads.
///
/// Stores the whole collection as a single JSON string under one key in the
/// `layer_uploads` box, mirroring `TrackRecordLocalDataSource`. The box is
/// opened once in `main_common.dart` at startup.
abstract class LayerUploadLocalDataSource {
  Future<void> openBox();
  Future<List<LayerUploadModel>> getAll();
  Future<LayerUploadModel?> getById(String uploadId);
  Future<void> save(LayerUploadModel upload);
  Future<void> delete(String uploadId);

  /// Non-terminal uploads left over from a previous session.
  Future<List<LayerUploadModel>> getResumable();
}

class LayerUploadLocalDataSourceImpl implements LayerUploadLocalDataSource {
  LayerUploadLocalDataSourceImpl({this.boxName = 'layer_uploads'});

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

  List<LayerUploadModel> _readAll() {
    final raw = _store.get(_key) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => LayerUploadModel.fromHiveJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeAll(List<LayerUploadModel> uploads) async {
    await _store.put(_key, jsonEncode(uploads.map((u) => u.toHiveJson()).toList()));
  }

  @override
  Future<List<LayerUploadModel>> getAll() async => _readAll();

  @override
  Future<LayerUploadModel?> getById(String uploadId) async {
    for (final u in _readAll()) {
      if (u.uploadId == uploadId) return u;
    }
    return null;
  }

  @override
  Future<void> save(LayerUploadModel upload) async {
    final all = List<LayerUploadModel>.from(_readAll());
    final idx = all.indexWhere((u) => u.uploadId == upload.uploadId);
    if (idx == -1) {
      all.add(upload);
    } else {
      all[idx] = upload;
    }
    await _writeAll(all);
  }

  @override
  Future<void> delete(String uploadId) async {
    final all = _readAll()..removeWhere((u) => u.uploadId == uploadId);
    await _writeAll(all);
  }

  @override
  Future<List<LayerUploadModel>> getResumable() async =>
      _readAll().where((u) => !u.isTerminal).toList();

  static const String _key = 'layer_uploads_v1';
}
