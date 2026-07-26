import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';

abstract class LayerUploadRepository {
  /// Full pipeline for a brand-new upload: init the session, send every
  /// chunk (batched, throttled, per-chunk retry), auto-finalize (`/tile` or
  /// `/save` depending on output format), then poll `/status` until a
  /// terminal state. Emits an updated [LayerUpload] after each meaningful
  /// step so the caller can persist/render progress as it happens.
  Stream<Either<Failure, LayerUpload>> uploadFile({
    required String filePath,
    required String filename,
    required int totalSize,
  });

  /// Resumes a previously persisted, non-terminal upload: re-syncs with the
  /// server (`GET /status`) to learn which chunks are already received,
  /// then continues the same pipeline as [uploadFile] from there.
  Stream<Either<Failure, LayerUpload>> resumeUpload(String uploadId);

  /// Re-runs finalization for a `failed` upload via `POST /retry`, then
  /// polls until terminal again.
  Stream<Either<Failure, LayerUpload>> retryUpload(String uploadId);

  /// One-shot status fetch, merged into the locally persisted record.
  Future<Either<Failure, LayerUpload>> getStatus(String uploadId);

  /// Cancels an in-progress upload. The tile server's `/cancel` endpoint
  /// always answers HTTP 500 even when it succeeds — this treats that as a
  /// possible success and verifies via `GET /status` before reporting
  /// failure (see docs/adr/0002-tileserver-chunk-upload-quirks.md).
  Future<Either<Failure, LayerUpload>> cancelUpload(String uploadId);

  /// Best-effort server-side cancel (failure ignored) plus local-record
  /// removal — used when the user discards a resumable upload outright.
  Future<Either<Failure, Unit>> discardUpload(String uploadId);

  /// Non-terminal uploads persisted from a previous session, newest first.
  Future<Either<Failure, List<LayerUpload>>> getResumableUploads();

  /// Manual publish step. Never called automatically by [uploadFile].
  Future<Either<Failure, Unit>> publishToGeoserver(String uploadId);
}
