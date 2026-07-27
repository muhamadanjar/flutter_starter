import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/external_dio_client.dart';

abstract class LayerUploadRemoteDataSource {
  Future<Map<String, dynamic>> initUpload({
    required String filename,
    required int totalSize,
    required String outputFormat,
    int? maxZoom,
  });

  Future<Map<String, dynamic>> sendChunk({
    required String uploadId,
    required int chunkIndex,
    required Uint8List bytes,
  });

  Future<Map<String, dynamic>> getStatus(String uploadId);

  Future<Map<String, dynamic>> triggerTile({
    required String uploadId,
    String? outputFormat,
    int? maxZoom,
  });

  Future<Map<String, dynamic>> saveGeojson(String uploadId);

  Future<Map<String, dynamic>> publishToGeoserver(String uploadId);

  Future<Map<String, dynamic>> retry(String uploadId);

  /// Cancels the upload. Per docs/adr/0002-tileserver-chunk-upload-quirks.md
  /// this endpoint always returns HTTP 500 even on success — this method
  /// swallows exactly that case (a [ServerException] with `statusCode 500`)
  /// and returns normally. Any other exception is rethrown; the caller is
  /// still responsible for confirming success via [getStatus].
  Future<void> cancel(String uploadId);
}

/// Talks to the tile server's `/api/v1/uploads/*` chunked-upload endpoints.
class LayerUploadRemoteDataSourceImpl implements LayerUploadRemoteDataSource {
  LayerUploadRemoteDataSourceImpl(this._client);

  final ExternalDioClient _client;

  @override
  Future<Map<String, dynamic>> initUpload({
    required String filename,
    required int totalSize,
    required String outputFormat,
    int? maxZoom,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/uploads/init',
      data: {
        'filename': filename,
        'total_size': totalSize,
        'output_format': outputFormat,
        if (maxZoom != null) 'max_zoom': maxZoom,
      },
    );
    return response.data ?? const {};
  }

  @override
  Future<Map<String, dynamic>> sendChunk({
    required String uploadId,
    required int chunkIndex,
    required Uint8List bytes,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/uploads/$uploadId/$chunkIndex',
      data: bytes,
      options: Options(contentType: 'application/octet-stream'),
    );
    return response.data ?? const {};
  }

  @override
  Future<Map<String, dynamic>> getStatus(String uploadId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/uploads/$uploadId/status',
    );
    return response.data ?? const {};
  }

  @override
  Future<Map<String, dynamic>> triggerTile({
    required String uploadId,
    String? outputFormat,
    int? maxZoom,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/uploads/$uploadId/tile',
      queryParameters: {
        if (outputFormat != null) 'output_format': outputFormat,
        if (maxZoom != null) 'max_zoom': maxZoom,
      },
    );
    return response.data ?? const {};
  }

  @override
  Future<Map<String, dynamic>> saveGeojson(String uploadId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/uploads/$uploadId/save',
    );
    return response.data ?? const {};
  }

  @override
  Future<Map<String, dynamic>> publishToGeoserver(String uploadId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/uploads/$uploadId/geoserver',
    );
    return response.data ?? const {};
  }

  @override
  Future<Map<String, dynamic>> retry(String uploadId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/uploads/$uploadId/retry',
    );
    return response.data ?? const {};
  }

  @override
  Future<void> cancel(String uploadId) async {
    try {
      await _client.post<Map<String, dynamic>>('/api/v1/uploads/$uploadId/cancel');
    } on ServerException catch (e) {
      if (e.statusCode == 500) return;
      rethrow;
    }
  }
}
