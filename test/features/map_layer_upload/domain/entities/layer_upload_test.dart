import 'package:enterprise_flutter_app/features/map_layer_upload/domain/entities/layer_upload.dart';
import 'package:flutter_test/flutter_test.dart';

LayerUpload _upload({
  int totalChunks = 4,
  Set<int> uploadedChunkIndexes = const {},
  LayerUploadStatus status = LayerUploadStatus.uploading,
}) {
  return LayerUpload(
    uploadId: 'u1',
    layerId: 'l1',
    filename: 'test.tif',
    filePath: '/tmp/test.tif',
    totalSize: 4000,
    chunkSize: 1000,
    totalChunks: totalChunks,
    uploadedChunkIndexes: uploadedChunkIndexes,
    outputFormat: LayerOutputFormat.raster,
    status: status,
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('LayerOutputFormatX.fromFilename', () {
    test('raster extensions', () {
      expect(LayerOutputFormatX.fromFilename('a.tif'), LayerOutputFormat.raster);
      expect(LayerOutputFormatX.fromFilename('a.TIFF'), LayerOutputFormat.raster);
    });
    test('vector extensions', () {
      expect(LayerOutputFormatX.fromFilename('a.geojson'), LayerOutputFormat.vector);
      expect(LayerOutputFormatX.fromFilename('a.zip'), LayerOutputFormat.vector);
    });
    test('unknown extension defaults to raster', () {
      expect(LayerOutputFormatX.fromFilename('a.xyz'), LayerOutputFormat.raster);
    });
  });

  group('LayerUploadStatusX.fromApiValue', () {
    test('round-trips known values', () {
      for (final s in LayerUploadStatus.values) {
        expect(LayerUploadStatusX.fromApiValue(s.name), s);
      }
    });
    test('unknown value defaults to pending', () {
      expect(LayerUploadStatusX.fromApiValue('bogus'), LayerUploadStatus.pending);
    });
  });

  group('LayerUpload computed properties', () {
    test('progressPercent is 0 when totalChunks is 0', () {
      final upload = _upload(totalChunks: 0);
      expect(upload.progressPercent, 0);
    });

    test('progressPercent reflects uploaded ratio', () {
      final upload = _upload(totalChunks: 4, uploadedChunkIndexes: {0, 1});
      expect(upload.progressPercent, 50);
    });

    test('isFullyUploaded is false until every index is present', () {
      final upload = _upload(totalChunks: 2, uploadedChunkIndexes: {0});
      expect(upload.isFullyUploaded, isFalse);
      final complete = _upload(totalChunks: 2, uploadedChunkIndexes: {0, 1});
      expect(complete.isFullyUploaded, isTrue);
    });

    test('isTerminal is true only for done/failed/cancelled', () {
      for (final s in [
        LayerUploadStatus.pending,
        LayerUploadStatus.uploading,
        LayerUploadStatus.uploaded,
        LayerUploadStatus.processing,
      ]) {
        expect(_upload(status: s).isTerminal, isFalse, reason: '$s should not be terminal');
      }
      for (final s in [
        LayerUploadStatus.done,
        LayerUploadStatus.failed,
        LayerUploadStatus.cancelled,
      ]) {
        expect(_upload(status: s).isTerminal, isTrue, reason: '$s should be terminal');
      }
    });

    test('canResume is the inverse of isTerminal', () {
      expect(_upload(status: LayerUploadStatus.uploading).canResume, isTrue);
      expect(_upload(status: LayerUploadStatus.done).canResume, isFalse);
    });

    test('pendingChunkIndexes lists only missing indexes, in order', () {
      final upload = _upload(totalChunks: 4, uploadedChunkIndexes: {1, 3});
      expect(upload.pendingChunkIndexes(), [0, 2]);
    });

    test('markChunkUploaded adds the index and flips status to uploading', () {
      final upload = _upload(totalChunks: 4, status: LayerUploadStatus.pending);
      final updated = upload.markChunkUploaded(2);
      expect(updated.uploadedChunkIndexes, {2});
      expect(updated.status, LayerUploadStatus.uploading);
    });

    test('markChunkUploaded is a no-op if the index is already present', () {
      final upload = _upload(uploadedChunkIndexes: {2}, status: LayerUploadStatus.done);
      final updated = upload.markChunkUploaded(2);
      expect(identical(updated, upload), isTrue);
    });

    test('copyWith overrides only the given fields', () {
      final upload = _upload();
      final updated = upload.copyWith(status: LayerUploadStatus.failed, errorMessage: 'boom');
      expect(updated.status, LayerUploadStatus.failed);
      expect(updated.errorMessage, 'boom');
      expect(updated.uploadId, upload.uploadId);
      expect(updated.totalChunks, upload.totalChunks);
    });
  });
}
