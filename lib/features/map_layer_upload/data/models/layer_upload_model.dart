import '../../domain/entities/layer_upload.dart';

class LayerUploadModel extends LayerUpload {
  const LayerUploadModel({
    required super.uploadId,
    required super.layerId,
    required super.filename,
    required super.filePath,
    required super.totalSize,
    required super.chunkSize,
    required super.totalChunks,
    super.uploadedChunkIndexes,
    required super.outputFormat,
    super.status,
    super.errorMessage,
    super.tileUrlTemplate,
    required super.updatedAt,
  });

  factory LayerUploadModel.fromEntity(LayerUpload e) => LayerUploadModel(
        uploadId: e.uploadId,
        layerId: e.layerId,
        filename: e.filename,
        filePath: e.filePath,
        totalSize: e.totalSize,
        chunkSize: e.chunkSize,
        totalChunks: e.totalChunks,
        uploadedChunkIndexes: e.uploadedChunkIndexes,
        outputFormat: e.outputFormat,
        status: e.status,
        errorMessage: e.errorMessage,
        tileUrlTemplate: e.tileUrlTemplate,
        updatedAt: e.updatedAt,
      );

  /// Builds the initial entity from `POST /uploads/init`'s response.
  factory LayerUploadModel.fromInitResponse(
    Map<String, dynamic> json, {
    required String filePath,
    required String filename,
    required int totalSize,
    required LayerOutputFormat outputFormat,
  }) {
    return LayerUploadModel(
      uploadId: json['upload_id'] as String,
      layerId: json['layer_id'] as String,
      filename: filename,
      filePath: filePath,
      totalSize: totalSize,
      chunkSize: json['chunk_size'] as int,
      totalChunks: json['total_chunks'] as int,
      outputFormat: outputFormat,
      status: LayerUploadStatus.pending,
      updatedAt: DateTime.now(),
    );
  }

  /// Local (Hive) persistence shape — a single JSON string per record,
  /// mirroring `TrackRecordModel`'s pattern.
  factory LayerUploadModel.fromHiveJson(Map<String, dynamic> json) {
    final rawIndexes = json['uploadedChunkIndexes'] as List? ?? const [];
    return LayerUploadModel(
      uploadId: json['uploadId'] as String,
      layerId: json['layerId'] as String,
      filename: json['filename'] as String,
      filePath: json['filePath'] as String,
      totalSize: json['totalSize'] as int,
      chunkSize: json['chunkSize'] as int,
      totalChunks: json['totalChunks'] as int,
      uploadedChunkIndexes: {for (final i in rawIndexes) i as int},
      outputFormat: LayerOutputFormatX.fromApiValue(json['outputFormat'] as String),
      status: LayerUploadStatusX.fromApiValue(json['status'] as String),
      errorMessage: json['errorMessage'] as String?,
      tileUrlTemplate: json['tileUrlTemplate'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Merges a `ChunkUploadResponse` into this entity. The response itself
  /// does not say which index was just sent — the caller (who made the
  /// request) passes it.
  LayerUploadModel mergeChunkResponse(
    Map<String, dynamic> json, {
    required int chunkIndex,
  }) {
    final isComplete = json['is_complete'] as bool? ?? false;
    return LayerUploadModel.fromEntity(
      markChunkUploaded(chunkIndex).copyWith(
        status: isComplete ? LayerUploadStatus.uploaded : LayerUploadStatus.uploading,
        tileUrlTemplate: json['tile_url_template'] as String? ?? tileUrlTemplate,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Merges a `JobStatusResponse` (`GET /status`). The server's `chunk_map`
  /// (when present) is the source of truth for confirmed chunk indexes.
  LayerUploadModel mergeStatusResponse(Map<String, dynamic> json) {
    final chunkMap = json['chunk_map'] as Map?;
    final serverIndexes = chunkMap == null
        ? <int>{}
        : {for (final k in chunkMap.keys) int.parse(k.toString())};
    final statusValue = json['status'] as String?;
    return LayerUploadModel.fromEntity(
      copyWith(
        status: statusValue == null
            ? status
            : LayerUploadStatusX.fromApiValue(statusValue),
        uploadedChunkIndexes: {...uploadedChunkIndexes, ...serverIndexes},
        errorMessage: json['error_message'] as String?,
        tileUrlTemplate: json['tile_url_template'] as String? ?? tileUrlTemplate,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Merges a finalize response (`/tile`, `/save` or `/retry`). `/save` has
  /// been observed to already include a terminal `status` synchronously;
  /// when absent, the upload is assumed to have moved into `processing`
  /// (polling picks up the real terminal status afterward).
  LayerUploadModel mergeFinalizeResponse(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    return LayerUploadModel.fromEntity(
      copyWith(
        status: statusStr == null
            ? LayerUploadStatus.processing
            : LayerUploadStatusX.fromApiValue(statusStr),
        tileUrlTemplate: json['tile_url_template'] as String? ?? tileUrlTemplate,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> toHiveJson() => {
        'uploadId': uploadId,
        'layerId': layerId,
        'filename': filename,
        'filePath': filePath,
        'totalSize': totalSize,
        'chunkSize': chunkSize,
        'totalChunks': totalChunks,
        'uploadedChunkIndexes': uploadedChunkIndexes.toList(),
        'outputFormat': outputFormat.apiValue,
        'status': status.name,
        'errorMessage': errorMessage,
        'tileUrlTemplate': tileUrlTemplate,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
