import 'package:enterprise_flutter_app/features/map_layer_upload/data/models/layer_upload_model.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/domain/entities/layer_upload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayerUploadModel.fromInitResponse', () {
    test('builds a pending upload from the init response', () {
      final model = LayerUploadModel.fromInitResponse(
        {
          'upload_id': 'u1',
          'layer_id': 'l1',
          'message': 'ok',
          'chunk_size': 10485760,
          'total_chunks': 3,
        },
        filePath: '/tmp/a.tif',
        filename: 'a.tif',
        totalSize: 30000000,
        outputFormat: LayerOutputFormat.raster,
      );

      expect(model.uploadId, 'u1');
      expect(model.layerId, 'l1');
      expect(model.chunkSize, 10485760);
      expect(model.totalChunks, 3);
      expect(model.status, LayerUploadStatus.pending);
      expect(model.uploadedChunkIndexes, isEmpty);
    });
  });

  group('LayerUploadModel.mergeChunkResponse', () {
    test('marks the chunk uploaded and flips to uploading when not complete', () {
      final base = LayerUploadModel.fromInitResponse(
        {'upload_id': 'u1', 'layer_id': 'l1', 'message': '', 'chunk_size': 10, 'total_chunks': 2},
        filePath: '/tmp/a.tif',
        filename: 'a.tif',
        totalSize: 20,
        outputFormat: LayerOutputFormat.raster,
      );

      final merged = base.mergeChunkResponse(
        {
          'upload_id': 'u1',
          'received_bytes': 10,
          'total_size': 20,
          'uploaded_chunks': 1,
          'total_chunks': 2,
          'progress_percent': 50.0,
          'is_complete': false,
        },
        chunkIndex: 0,
      );

      expect(merged.uploadedChunkIndexes, {0});
      expect(merged.status, LayerUploadStatus.uploading);
    });

    test('flips to uploaded when is_complete is true', () {
      final base = LayerUploadModel.fromInitResponse(
        {'upload_id': 'u1', 'layer_id': 'l1', 'message': '', 'chunk_size': 20, 'total_chunks': 1},
        filePath: '/tmp/a.tif',
        filename: 'a.tif',
        totalSize: 20,
        outputFormat: LayerOutputFormat.raster,
      );

      final merged = base.mergeChunkResponse(
        {
          'upload_id': 'u1',
          'received_bytes': 20,
          'total_size': 20,
          'uploaded_chunks': 1,
          'total_chunks': 1,
          'progress_percent': 100.0,
          'is_complete': true,
        },
        chunkIndex: 0,
      );

      expect(merged.status, LayerUploadStatus.uploaded);
      expect(merged.isFullyUploaded, isTrue);
    });
  });

  group('LayerUploadModel.mergeStatusResponse', () {
    test('parses status, error_message, tile_url_template and chunk_map', () {
      final base = LayerUploadModel.fromInitResponse(
        {'upload_id': 'u1', 'layer_id': 'l1', 'message': '', 'chunk_size': 10, 'total_chunks': 2},
        filePath: '/tmp/a.geojson',
        filename: 'a.geojson',
        totalSize: 20,
        outputFormat: LayerOutputFormat.vector,
      );

      final merged = base.mergeStatusResponse({
        'upload_id': 'u1',
        'layer_id': 'l1',
        'status': 'done',
        'received_bytes': 20,
        'total_size': 20,
        'uploaded_chunks': 2,
        'total_chunks': 2,
        'progress_percent': 100.0,
        'chunk_map': {'0': 10, '1': 10},
        'error_message': null,
        'tile_url_template': '/tiles/l1/{z}/{x}/{y}.png',
        'bbox': [106.0, -6.0, 106.1, -6.1],
      });

      expect(merged.status, LayerUploadStatus.done);
      expect(merged.uploadedChunkIndexes, {0, 1});
      expect(merged.tileUrlTemplate, '/tiles/l1/{z}/{x}/{y}.png');
    });

    test('a null chunk_map keeps the existing uploaded indexes', () {
      final base = LayerUploadModel.fromInitResponse(
        {'upload_id': 'u1', 'layer_id': 'l1', 'message': '', 'chunk_size': 10, 'total_chunks': 2},
        filePath: '/tmp/a.tif',
        filename: 'a.tif',
        totalSize: 20,
        outputFormat: LayerOutputFormat.raster,
      ).mergeChunkResponse({'is_complete': false}, chunkIndex: 0);

      final merged = base.mergeStatusResponse({
        'status': 'uploaded',
        'chunk_map': null,
        'error_message': null,
        'tile_url_template': null,
      });

      expect(merged.uploadedChunkIndexes, {0});
    });
  });

  group('LayerUploadModel.mergeFinalizeResponse', () {
    test('uses the response status when present (e.g. /save returns done directly)', () {
      final base = LayerUploadModel.fromInitResponse(
        {'upload_id': 'u1', 'layer_id': 'l1', 'message': '', 'chunk_size': 10, 'total_chunks': 1},
        filePath: '/tmp/a.geojson',
        filename: 'a.geojson',
        totalSize: 10,
        outputFormat: LayerOutputFormat.vector,
      );

      final merged = base.mergeFinalizeResponse({
        'message': 'Layer saved',
        'upload_id': 'u1',
        'layer_id': 'l1',
        'layer_type': 'geojson',
        'tile_url_template': '/l1/data.geojson',
        'status': 'done',
      });

      expect(merged.status, LayerUploadStatus.done);
      expect(merged.tileUrlTemplate, '/l1/data.geojson');
    });

    test('defaults to processing when the response has no status field', () {
      final base = LayerUploadModel.fromInitResponse(
        {'upload_id': 'u1', 'layer_id': 'l1', 'message': '', 'chunk_size': 10, 'total_chunks': 1},
        filePath: '/tmp/a.tif',
        filename: 'a.tif',
        totalSize: 10,
        outputFormat: LayerOutputFormat.raster,
      );

      final merged = base.mergeFinalizeResponse(<String, dynamic>{});

      expect(merged.status, LayerUploadStatus.processing);
    });
  });

  group('Hive JSON round-trip', () {
    test('toHiveJson then fromHiveJson reproduces the same fields', () {
      final original = LayerUploadModel.fromInitResponse(
        {'upload_id': 'u1', 'layer_id': 'l1', 'message': '', 'chunk_size': 10, 'total_chunks': 2},
        filePath: '/tmp/a.tif',
        filename: 'a.tif',
        totalSize: 20,
        outputFormat: LayerOutputFormat.raster,
      ).mergeChunkResponse({'is_complete': false}, chunkIndex: 0);

      final roundTripped = LayerUploadModel.fromHiveJson(original.toHiveJson());

      expect(roundTripped.uploadId, original.uploadId);
      expect(roundTripped.layerId, original.layerId);
      expect(roundTripped.filename, original.filename);
      expect(roundTripped.filePath, original.filePath);
      expect(roundTripped.totalSize, original.totalSize);
      expect(roundTripped.chunkSize, original.chunkSize);
      expect(roundTripped.totalChunks, original.totalChunks);
      expect(roundTripped.uploadedChunkIndexes, original.uploadedChunkIndexes);
      expect(roundTripped.outputFormat, original.outputFormat);
      expect(roundTripped.status, original.status);
      expect(roundTripped.updatedAt, original.updatedAt);
    });
  });
}
