import 'dart:io';
import 'dart:typed_data';

import 'package:enterprise_flutter_app/core/errors/exceptions.dart';
import 'package:enterprise_flutter_app/core/errors/failures.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/datasources/layer_upload_local_datasource.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/datasources/layer_upload_remote_datasource.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/models/layer_upload_model.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/repositories/layer_upload_repository_impl.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/domain/entities/layer_upload.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemoteDataSource implements LayerUploadRemoteDataSource {
  int chunkCalls = 0;
  int chunkFailuresRemaining = 0;
  bool cancelThrows500 = false;
  String finalizeStatus = 'done';

  final Map<String, String> _serverStatus = {};

  @override
  Future<Map<String, dynamic>> initUpload({
    required String filename,
    required int totalSize,
    required String outputFormat,
    int? maxZoom,
  }) async {
    _serverStatus['u1'] = 'pending';
    return {
      'upload_id': 'u1',
      'layer_id': 'l1',
      'message': 'ok',
      'chunk_size': 10,
      'total_chunks': 2,
    };
  }

  @override
  Future<Map<String, dynamic>> sendChunk({
    required String uploadId,
    required int chunkIndex,
    required Uint8List bytes,
  }) async {
    chunkCalls++;
    if (chunkFailuresRemaining > 0) {
      chunkFailuresRemaining--;
      throw const ServerException(message: 'boom', statusCode: 500);
    }
    return {
      'upload_id': uploadId,
      'received_bytes': (chunkIndex + 1) * 10,
      'total_size': 20,
      'uploaded_chunks': chunkIndex + 1,
      'total_chunks': 2,
      'progress_percent': (chunkIndex + 1) * 50.0,
      'is_complete': chunkIndex == 1,
    };
  }

  @override
  Future<Map<String, dynamic>> getStatus(String uploadId) async {
    return {
      'upload_id': uploadId,
      'layer_id': 'l1',
      'status': _serverStatus[uploadId] ?? 'uploaded',
      'chunk_map': null,
      'error_message': null,
      'tile_url_template': null,
    };
  }

  @override
  Future<Map<String, dynamic>> triggerTile({
    required String uploadId,
    String? outputFormat,
    int? maxZoom,
  }) async {
    return {'status': finalizeStatus};
  }

  @override
  Future<Map<String, dynamic>> saveGeojson(String uploadId) async {
    return {'status': finalizeStatus};
  }

  @override
  Future<Map<String, dynamic>> publishToGeoserver(String uploadId) async => {};

  @override
  Future<Map<String, dynamic>> retry(String uploadId) async => {'status': finalizeStatus};

  @override
  Future<void> cancel(String uploadId) async {
    _serverStatus[uploadId] = 'cancelled';
    if (cancelThrows500) return; // simulates the swallowed-500 contract
  }
}

class _FakeLocalDataSource implements LayerUploadLocalDataSource {
  final Map<String, LayerUploadModel> _store = {};

  @override
  Future<void> openBox() async {}

  @override
  Future<List<LayerUploadModel>> getAll() async => _store.values.toList();

  @override
  Future<LayerUploadModel?> getById(String uploadId) async => _store[uploadId];

  @override
  Future<void> save(LayerUploadModel upload) async => _store[upload.uploadId] = upload;

  @override
  Future<void> delete(String uploadId) async => _store.remove(uploadId);

  @override
  Future<List<LayerUploadModel>> getResumable() async =>
      _store.values.where((u) => !u.isTerminal).toList();
}

void main() {
  late _FakeRemoteDataSource remote;
  late _FakeLocalDataSource local;
  late LayerUploadRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemoteDataSource();
    local = _FakeLocalDataSource();
    repository = LayerUploadRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      chunkRetryInitialDelay: const Duration(milliseconds: 1),
      statusPollInterval: const Duration(milliseconds: 1),
    );
  });

  group('with a real temp file', () {
    late Directory tempDir;
    late File sourceFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('layer_upload_repo_test');
      sourceFile = File('${tempDir.path}/a.tif');
      await sourceFile.writeAsBytes(List<int>.filled(20, 7));
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('uploadFile reads real chunks from disk and completes to done', () async {
      final events = await repository
          .uploadFile(filePath: sourceFile.path, filename: 'a.tif', totalSize: 20)
          .toList();

      expect(events.every((e) => e.isRight()), isTrue, reason: events.toString());
      final last = events.last.fold((f) => throw f, (u) => u);
      expect(last.status, LayerUploadStatus.done);
      expect(remote.chunkCalls, 2);

      final saved = await local.getById('u1');
      expect(saved?.status, LayerUploadStatus.done);
    });

    test('a chunk that exhausts retries reports failure and stops', () async {
      remote.chunkFailuresRemaining = 100; // always fails
      final events = await repository
          .uploadFile(filePath: sourceFile.path, filename: 'a.tif', totalSize: 20)
          .toList();

      expect(events.last.isLeft(), isTrue);
      final failure = events.last.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
    });
  });

  test('cancelUpload treats the swallowed 500 as success once status confirms cancelled', () async {
    await local.save(LayerUploadModel(
      uploadId: 'u1',
      layerId: 'l1',
      filename: 'a.tif',
      filePath: '/tmp/a.tif',
      totalSize: 20,
      chunkSize: 10,
      totalChunks: 2,
      outputFormat: LayerOutputFormat.raster,
      status: LayerUploadStatus.uploading,
      updatedAt: DateTime(2026, 1, 1),
    ));
    remote.cancelThrows500 = true;

    final result = await repository.cancelUpload('u1');

    expect(result.isRight(), isTrue);
    final upload = result.fold((f) => throw f, (u) => u);
    expect(upload.status, LayerUploadStatus.cancelled);
  });

  test('discardUpload removes the local record even if the server cancel fails', () async {
    await local.save(LayerUploadModel(
      uploadId: 'u1',
      layerId: 'l1',
      filename: 'a.tif',
      filePath: '/tmp/a.tif',
      totalSize: 20,
      chunkSize: 10,
      totalChunks: 2,
      outputFormat: LayerOutputFormat.raster,
      status: LayerUploadStatus.uploading,
      updatedAt: DateTime(2026, 1, 1),
    ));

    final result = await repository.discardUpload('u1');

    expect(result.isRight(), isTrue);
    expect(await local.getById('u1'), isNull);
  });

  test('getResumableUploads returns only non-terminal records, newest first', () async {
    await local.save(LayerUploadModel(
      uploadId: 'old',
      layerId: 'l-old',
      filename: 'old.tif',
      filePath: '/tmp/old.tif',
      totalSize: 20,
      chunkSize: 10,
      totalChunks: 2,
      outputFormat: LayerOutputFormat.raster,
      status: LayerUploadStatus.uploading,
      updatedAt: DateTime(2026, 1, 1),
    ));
    await local.save(LayerUploadModel(
      uploadId: 'new',
      layerId: 'l-new',
      filename: 'new.tif',
      filePath: '/tmp/new.tif',
      totalSize: 20,
      chunkSize: 10,
      totalChunks: 2,
      outputFormat: LayerOutputFormat.raster,
      status: LayerUploadStatus.uploading,
      updatedAt: DateTime(2026, 1, 2),
    ));
    await local.save(LayerUploadModel(
      uploadId: 'done',
      layerId: 'l-done',
      filename: 'done.tif',
      filePath: '/tmp/done.tif',
      totalSize: 20,
      chunkSize: 10,
      totalChunks: 2,
      outputFormat: LayerOutputFormat.raster,
      status: LayerUploadStatus.done,
      updatedAt: DateTime(2026, 1, 3),
    ));

    final result = await repository.getResumableUploads();

    final uploads = result.fold((f) => throw f, (u) => u);
    expect(uploads.map((u) => u.uploadId), ['new', 'old']);
  });
}
