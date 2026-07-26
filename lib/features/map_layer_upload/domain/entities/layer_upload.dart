/// How the tile server should turn an uploaded file into a layer.
///
/// Auto-detected from the source filename's extension — the user never
/// picks this directly.
enum LayerOutputFormat { raster, vector }

extension LayerOutputFormatX on LayerOutputFormat {
  String get apiValue => this == LayerOutputFormat.raster ? 'raster' : 'vector';

  static LayerOutputFormat fromApiValue(String value) =>
      value == 'vector' ? LayerOutputFormat.vector : LayerOutputFormat.raster;

  /// `.tif`/`.tiff` → raster. `.geojson`/`.zip` (shapefile) → vector.
  /// Anything else defaults to raster.
  static LayerOutputFormat fromFilename(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'geojson':
      case 'json':
      case 'zip':
        return LayerOutputFormat.vector;
      default:
        return LayerOutputFormat.raster;
    }
  }
}

/// LayerUpload lifecycle. `done` and `cancelled` are confirmed live server
/// strings; `processing` and `failed` are best-effort guesses — see
/// docs/adr/0002-tileserver-chunk-upload-quirks.md.
enum LayerUploadStatus {
  pending,
  uploading,
  uploaded,
  processing,
  done,
  failed,
  cancelled,
}

extension LayerUploadStatusX on LayerUploadStatus {
  static LayerUploadStatus fromApiValue(String value) => LayerUploadStatus.values
      .firstWhere((s) => s.name == value, orElse: () => LayerUploadStatus.pending);
}

/// Aggregate root for one chunked file transfer to the tile server, from
/// selection through to a usable map layer. See CONTEXT.md "Layer Upload".
class LayerUpload {
  const LayerUpload({
    required this.uploadId,
    required this.layerId,
    required this.filename,
    required this.filePath,
    required this.totalSize,
    required this.chunkSize,
    required this.totalChunks,
    this.uploadedChunkIndexes = const {},
    required this.outputFormat,
    this.status = LayerUploadStatus.pending,
    this.errorMessage,
    this.tileUrlTemplate,
    required this.updatedAt,
  });

  final String uploadId;
  final String layerId;
  final String filename;
  final String filePath;
  final int totalSize;
  final int chunkSize;
  final int totalChunks;
  final Set<int> uploadedChunkIndexes;
  final LayerOutputFormat outputFormat;
  final LayerUploadStatus status;
  final String? errorMessage;
  final String? tileUrlTemplate;
  final DateTime updatedAt;

  int get uploadedChunkCount => uploadedChunkIndexes.length;

  double get progressPercent {
    if (totalChunks == 0) return 0;
    return (uploadedChunkCount / totalChunks) * 100;
  }

  bool get isFullyUploaded => totalChunks > 0 && uploadedChunkCount >= totalChunks;

  bool get isTerminal =>
      status == LayerUploadStatus.done ||
      status == LayerUploadStatus.failed ||
      status == LayerUploadStatus.cancelled;

  /// A prior session's upload is worth offering to resume when it hasn't
  /// finished, failed, or been cancelled.
  bool get canResume => !isTerminal;

  bool isChunkUploaded(int index) => uploadedChunkIndexes.contains(index);

  /// Chunk indexes not yet confirmed received by the server, ascending.
  List<int> pendingChunkIndexes() => [
        for (int i = 0; i < totalChunks; i++)
          if (!isChunkUploaded(i)) i,
      ];

  LayerUpload markChunkUploaded(int index) {
    if (isChunkUploaded(index)) return this;
    return copyWith(
      uploadedChunkIndexes: {...uploadedChunkIndexes, index},
      status: LayerUploadStatus.uploading,
    );
  }

  LayerUpload copyWith({
    String? uploadId,
    String? layerId,
    String? filename,
    String? filePath,
    int? totalSize,
    int? chunkSize,
    int? totalChunks,
    Set<int>? uploadedChunkIndexes,
    LayerOutputFormat? outputFormat,
    LayerUploadStatus? status,
    String? errorMessage,
    String? tileUrlTemplate,
    DateTime? updatedAt,
  }) {
    return LayerUpload(
      uploadId: uploadId ?? this.uploadId,
      layerId: layerId ?? this.layerId,
      filename: filename ?? this.filename,
      filePath: filePath ?? this.filePath,
      totalSize: totalSize ?? this.totalSize,
      chunkSize: chunkSize ?? this.chunkSize,
      totalChunks: totalChunks ?? this.totalChunks,
      uploadedChunkIndexes: uploadedChunkIndexes ?? this.uploadedChunkIndexes,
      outputFormat: outputFormat ?? this.outputFormat,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      tileUrlTemplate: tileUrlTemplate ?? this.tileUrlTemplate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
