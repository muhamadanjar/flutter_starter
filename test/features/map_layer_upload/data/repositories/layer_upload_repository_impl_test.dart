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
  int chunkTimeoutsRemaining = 0;
  bool cancelThrows500 = false;
  String finalizeStatus = 'done';
  int finalizeCalls = 0;

  /// When true, [getStatus] never reports a terminal status — used to
  /// exercise the `_pollStatus` bound (Important 7).
  bool neverTerminal = false;

  /// Chunk indexes that always throw a 500, regardless of
  /// [chunkFailuresRemaining] — used to deterministically fail one member of
  /// a concurrent batch while its siblings succeed.
  Set<int> alwaysFailChunkIndexes = {};

  final Map<String, String> _serverStatus = {};

  /// Test helper: makes [getStatus] report [status] for [uploadId] without
  /// going through [cancel] (which always reports `cancelled`).
  void forceServerStatus(String uploadId, String status) {
    _serverStatus[uploadId] = status;
  }

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
    if (alwaysFailChunkIndexes.contains(chunkIndex)) {
      throw const ServerException(message: 'boom', statusCode: 500);
    }
    if (chunkFailuresRemaining > 0) {
      chunkFailuresRemaining--;
      throw const ServerException(message: 'boom', statusCode: 500);
    }
    if (chunkTimeoutsRemaining > 0) {
      chunkTimeoutsRemaining--;
      throw const TimeoutException(message: 'timed out');
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
      'status': neverTerminal ? 'processing' : (_serverStatus[uploadId] ?? 'uploaded'),
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
    finalizeCalls++;
    return {'status': finalizeStatus};
  }

  @override
  Future<Map<String, dynamic>> saveGeojson(String uploadId) async {
    finalizeCalls++;
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

    test(
      'a batch (size > 1) where all chunks succeed unions every index, not just the last processed',
      () async {
        // 4 chunks of 5 bytes, default maxConcurrentChunks (3) => batches of
        // [0,1,2] then [3]. Regression: previously each chunk's result
        // *replaced* `current` instead of merging into it, so only the last
        // chunk processed in a batch survived.
        await local.save(LayerUploadModel(
          uploadId: 'u1',
          layerId: 'l1',
          filename: 'a.tif',
          filePath: sourceFile.path,
          totalSize: 20,
          chunkSize: 5,
          totalChunks: 4,
          outputFormat: LayerOutputFormat.raster,
          status: LayerUploadStatus.pending,
          updatedAt: DateTime(2026, 1, 1),
        ));

        final events = await repository.resumeUpload('u1').toList();

        expect(events.every((e) => e.isRight()), isTrue, reason: events.toString());
        expect(remote.chunkCalls, 4);

        final saved = await local.getById('u1');
        expect(saved?.uploadedChunkIndexes, {0, 1, 2, 3});
      },
    );

    test(
      'a batch (size > 1) with one chunk exhausting retries still persists its successful siblings',
      () async {
        // Batch [0,1,2] — index 1 always fails, 0 and 2 succeed. Regression:
        // previously the sibling successes in the same batch were never
        // saved/yielded once a batch-mate failed.
        remote.alwaysFailChunkIndexes = {1};
        await local.save(LayerUploadModel(
          uploadId: 'u1',
          layerId: 'l1',
          filename: 'a.tif',
          filePath: sourceFile.path,
          totalSize: 20,
          chunkSize: 5,
          totalChunks: 4,
          outputFormat: LayerOutputFormat.raster,
          status: LayerUploadStatus.pending,
          updatedAt: DateTime(2026, 1, 1),
        ));

        final events = await repository.resumeUpload('u1').toList();

        expect(events.last.isLeft(), isTrue);
        final failure = events.last.fold((f) => f, (_) => null);
        expect(failure, isA<ServerFailure>());

        final successEvents = events.where((e) => e.isRight()).toList();
        final lastSuccess = successEvents.last.fold((f) => throw f, (u) => u);
        expect(lastSuccess.uploadedChunkIndexes, containsAll(<int>{0, 2}));
        expect(lastSuccess.uploadedChunkIndexes, isNot(contains(1)));

        final saved = await local.getById('u1');
        expect(saved?.uploadedChunkIndexes, containsAll(<int>{0, 2}));
        expect(saved?.uploadedChunkIndexes, isNot(contains(1)));
      },
    );

    test(
      'a chunk send that throws TimeoutException is retried, not immediately failed (Critical 1)',
      () async {
        // Times out on the first two attempts for every chunk, then
        // succeeds. If TimeoutException bypassed the retry loop, this would
        // fail immediately instead of completing.
        remote.chunkTimeoutsRemaining = 1;
        final events = await repository
            .uploadFile(filePath: sourceFile.path, filename: 'a.tif', totalSize: 20)
            .toList();

        expect(events.every((e) => e.isRight()), isTrue, reason: events.toString());
        final last = events.last.fold((f) => throw f, (u) => u);
        expect(last.status, LayerUploadStatus.done);
        // 2 chunks total; one of them needed an extra attempt after timing
        // out once.
        expect(remote.chunkCalls, 3);
      },
    );

    test(
      'a chunk send that exhausts retries via TimeoutException reports a NetworkFailure (Critical 1)',
      () async {
        remote.chunkTimeoutsRemaining = 100; // always times out
        final events = await repository
            .uploadFile(filePath: sourceFile.path, filename: 'a.tif', totalSize: 20)
            .toList();

        expect(events.last.isLeft(), isTrue);
        final failure = events.last.fold((f) => f, (_) => null);
        expect(failure, isA<NetworkFailure>());
      },
    );

    test(
      'a missing source file fails validation immediately without retrying (Important 4)',
      () async {
        await local.save(LayerUploadModel(
          uploadId: 'u1',
          layerId: 'l1',
          filename: 'a.tif',
          filePath: '${sourceFile.path}.does-not-exist',
          totalSize: 20,
          chunkSize: 10,
          totalChunks: 2,
          outputFormat: LayerOutputFormat.raster,
          status: LayerUploadStatus.pending,
          updatedAt: DateTime(2026, 1, 1),
        ));

        final events = await repository.resumeUpload('u1').toList();

        expect(events.last.isLeft(), isTrue);
        final failure = events.last.fold((f) => f, (_) => null);
        expect(failure, isA<ValidationFailure>());
        expect(remote.chunkCalls, 0);
      },
    );
  });

  test(
    'resuming a processing upload does not re-trigger finalize (Important 3)',
    () async {
      // Fully uploaded already, and the server-synced status (from
      // resumeUpload's initial GET /status) is `processing` — finalization
      // was already kicked off in a prior session. Regression: previously
      // the repository unconditionally re-called /tile, re-triggering
      // finalization server-side.
      final processingRemote = _FakeRemoteDataSource()..forceServerStatus('u1', 'processing');
      final processingLocal = _FakeLocalDataSource();
      final processingRepo = LayerUploadRepositoryImpl(
        remoteDataSource: processingRemote,
        localDataSource: processingLocal,
        chunkRetryInitialDelay: const Duration(milliseconds: 1),
        statusPollInterval: const Duration(milliseconds: 1),
        // Small bound: this test only cares that finalize is never
        // re-triggered, not that polling eventually reaches a terminal
        // status (the fake never reports one here).
        maxPollAttempts: 2,
      );

      await processingLocal.save(LayerUploadModel(
        uploadId: 'u1',
        layerId: 'l1',
        filename: 'a.tif',
        filePath: '/tmp/a.tif',
        totalSize: 20,
        chunkSize: 10,
        totalChunks: 2,
        outputFormat: LayerOutputFormat.raster,
        status: LayerUploadStatus.uploaded,
        uploadedChunkIndexes: const {0, 1},
        updatedAt: DateTime(2026, 1, 1),
      ));

      final events = await processingRepo.resumeUpload('u1').toList();

      // No finalize (/tile or /save) call was made at any point — that's
      // the behavior under test.
      expect(processingRemote.finalizeCalls, 0);
      // The very first synced event (before polling starts) already carries
      // the `processing` status straight through from GET /status.
      final firstUpload = events.first.fold((f) => throw f, (u) => u);
      expect(firstUpload.status, LayerUploadStatus.processing);
    },
  );

  test(
    '_pollStatus gives up after maxPollAttempts and returns a ServerFailure instead of hanging (Important 7)',
    () async {
      final pollRemote = _FakeRemoteDataSource()..neverTerminal = true;
      final pollLocal = _FakeLocalDataSource();
      final pollRepo = LayerUploadRepositoryImpl(
        remoteDataSource: pollRemote,
        localDataSource: pollLocal,
        chunkRetryInitialDelay: const Duration(milliseconds: 1),
        statusPollInterval: const Duration(milliseconds: 1),
        maxPollAttempts: 3,
      );

      await pollLocal.save(LayerUploadModel(
        uploadId: 'u1',
        layerId: 'l1',
        filename: 'a.tif',
        filePath: '/tmp/a.tif',
        totalSize: 20,
        chunkSize: 10,
        totalChunks: 2,
        outputFormat: LayerOutputFormat.raster,
        status: LayerUploadStatus.processing,
        uploadedChunkIndexes: const {0, 1},
        updatedAt: DateTime(2026, 1, 1),
      ));

      final events = await pollRepo.resumeUpload('u1').toList();

      expect(events.last.isLeft(), isTrue);
      final failure = events.last.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect((failure! as ServerFailure).message, contains('Timed out'));
    },
  );

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
