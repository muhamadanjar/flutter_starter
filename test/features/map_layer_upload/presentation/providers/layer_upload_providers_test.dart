import 'dart:async';

import 'package:enterprise_flutter_app/core/errors/failures.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/domain/entities/layer_upload.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/domain/repositories/layer_upload_repository.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/presentation/providers/layer_upload_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

LayerUpload _upload(LayerUploadStatus status) => LayerUpload(
      uploadId: 'u1',
      layerId: 'l1',
      filename: 'a.tif',
      filePath: '/tmp/a.tif',
      totalSize: 20,
      chunkSize: 10,
      totalChunks: 2,
      outputFormat: LayerOutputFormat.raster,
      status: status,
      updatedAt: DateTime(2026, 1, 1),
    );

/// Minimal fake: only [uploadFile] and [cancelUpload] are exercised by
/// [ActiveLayerUploadNotifier.cancel] — the rest throw if ever hit.
class _FakeRepository implements LayerUploadRepository {
  final _uploadController = StreamController<Either<Failure, LayerUpload>>();
  int cancelCalls = 0;

  @override
  Stream<Either<Failure, LayerUpload>> uploadFile({
    required String filePath,
    required String filename,
    required int totalSize,
  }) =>
      _uploadController.stream;

  @override
  Future<Either<Failure, LayerUpload>> cancelUpload(String uploadId) async {
    cancelCalls++;
    return right(_upload(LayerUploadStatus.cancelled));
  }

  @override
  Stream<Either<Failure, LayerUpload>> resumeUpload(String uploadId) => throw UnimplementedError();

  @override
  Stream<Either<Failure, LayerUpload>> retryUpload(String uploadId) => throw UnimplementedError();

  @override
  Future<Either<Failure, LayerUpload>> getStatus(String uploadId) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> discardUpload(String uploadId) => throw UnimplementedError();

  @override
  Future<Either<Failure, List<LayerUpload>>> getResumableUploads() => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> publishToGeoserver(String uploadId) => throw UnimplementedError();
}

void main() {
  test(
    'cancel() stops the active pipeline subscription before applying the cancelled state '
    '(Critical 2): stale events emitted after cancel() must not overwrite it',
    () async {
      final fakeRepo = _FakeRepository();
      final container = ProviderContainer(
        overrides: [layerUploadRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo._uploadController.close);

      final notifier = container.read(activeLayerUploadProvider.notifier);

      notifier.start(filePath: '/tmp/a.tif', filename: 'a.tif', totalSize: 20);
      fakeRepo._uploadController.add(right(_upload(LayerUploadStatus.uploading)));
      // Let the stream event propagate.
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(activeLayerUploadProvider)?.valueOrNull?.status,
        LayerUploadStatus.uploading,
      );

      await notifier.cancel();
      expect(fakeRepo.cancelCalls, 1);
      expect(
        container.read(activeLayerUploadProvider)?.valueOrNull?.status,
        LayerUploadStatus.cancelled,
      );

      // Regression: previously the still-running upload stream's
      // subscription was never cancelled, so a late event like this would
      // overwrite the cancelled state with stale progress.
      fakeRepo._uploadController.add(right(_upload(LayerUploadStatus.uploading)));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(activeLayerUploadProvider)?.valueOrNull?.status,
        LayerUploadStatus.cancelled,
        reason: 'a stale pipeline event after cancel() must not overwrite the cancelled state',
      );
    },
  );
}
