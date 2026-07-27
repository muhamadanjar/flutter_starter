import 'dart:async' hide TimeoutException;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/layer_upload.dart';
import '../../domain/repositories/layer_upload_repository.dart';
import '../datasources/layer_upload_local_datasource.dart';
import '../datasources/layer_upload_remote_datasource.dart';
import '../models/layer_upload_model.dart';

/// Orchestrates the full chunked-upload pipeline: init -> send chunks
/// (batched, throttled, per-chunk retried) -> auto-finalize -> poll status.
///
/// Chunks are sent in fixed-size batches of [maxConcurrentChunks] (via
/// `Future.wait`) rather than a fully dynamic sliding-window pool. This
/// satisfies "up to N concurrent" and "isolated per-chunk retry" with far
/// less concurrency-bug surface than a hand-rolled pool; the only difference
/// from a true sliding window is that a batch waits for its slowest member
/// before the next batch starts.
class LayerUploadRepositoryImpl implements LayerUploadRepository {
  LayerUploadRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.maxConcurrentChunks = 3,
    this.maxChunkRetries = 3,
    this.chunkRetryInitialDelay = const Duration(milliseconds: 500),
    this.statusPollInterval = const Duration(seconds: 3),
    this.maxPollAttempts = 100,
  });

  final LayerUploadRemoteDataSource remoteDataSource;
  final LayerUploadLocalDataSource localDataSource;
  final int maxConcurrentChunks;
  final int maxChunkRetries;
  final Duration chunkRetryInitialDelay;
  final Duration statusPollInterval;

  /// Upper bound on the number of times [_pollStatus] will poll
  /// `GET /status` waiting for a terminal state before giving up. Combined
  /// with the default [statusPollInterval] of 3s, the default of 100 gives
  /// ~5 minutes before [_pollStatus] surfaces a [ServerFailure] instead of
  /// polling forever (see ADR 0002 — /tile failures on raster uploads
  /// currently never set a `failed` status server-side).
  final int maxPollAttempts;

  @override
  Stream<Either<Failure, LayerUpload>> uploadFile({
    required String filePath,
    required String filename,
    required int totalSize,
  }) async* {
    final outputFormat = LayerOutputFormatX.fromFilename(filename);
    LayerUploadModel initial;
    try {
      final json = await remoteDataSource.initUpload(
        filename: filename,
        totalSize: totalSize,
        outputFormat: outputFormat.apiValue,
      );
      initial = LayerUploadModel.fromInitResponse(
        json,
        filePath: filePath,
        filename: filename,
        totalSize: totalSize,
        outputFormat: outputFormat,
      );
    } on NetworkException catch (e) {
      yield left(NetworkFailure(message: e.message ?? 'No internet connection'));
      return;
    } on TimeoutException catch (e) {
      yield left(NetworkFailure(message: e.message ?? 'Request timed out'));
      return;
    } on ValidationException catch (e) {
      yield left(ValidationFailure(message: e.message ?? 'Invalid file', fieldErrors: e.fieldErrors));
      return;
    } on ServerException catch (e) {
      yield left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
      return;
    } catch (e) {
      yield left(UnknownFailure(message: e.toString()));
      return;
    }

    await localDataSource.save(initial);
    yield right(initial);

    yield* _runPipeline(initial);
  }

  @override
  Stream<Either<Failure, LayerUpload>> resumeUpload(String uploadId) async* {
    final local = await localDataSource.getById(uploadId);
    if (local == null) {
      yield left(ServerFailure(message: 'No local record for upload $uploadId'));
      return;
    }

    LayerUploadModel synced;
    try {
      final json = await remoteDataSource.getStatus(uploadId);
      synced = local.mergeStatusResponse(json);
    } on NetworkException catch (e) {
      yield left(NetworkFailure(message: e.message ?? 'No internet connection'));
      return;
    } on TimeoutException catch (e) {
      yield left(NetworkFailure(message: e.message ?? 'Request timed out'));
      return;
    } on ServerException catch (e) {
      yield left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
      return;
    } catch (e) {
      yield left(UnknownFailure(message: e.toString()));
      return;
    }

    await localDataSource.save(synced);
    yield right(synced);

    if (synced.isTerminal) return;
    yield* _runPipeline(synced);
  }

  @override
  Stream<Either<Failure, LayerUpload>> retryUpload(String uploadId) async* {
    final local = await localDataSource.getById(uploadId);
    if (local == null) {
      yield left(ServerFailure(message: 'No local record for upload $uploadId'));
      return;
    }

    LayerUploadModel current = local;
    try {
      final json = await remoteDataSource.retry(uploadId);
      current = current.mergeFinalizeResponse(json);
    } on NetworkException catch (e) {
      yield left(NetworkFailure(message: e.message ?? 'No internet connection'));
      return;
    } on TimeoutException catch (e) {
      yield left(NetworkFailure(message: e.message ?? 'Request timed out'));
      return;
    } on ServerException catch (e) {
      yield left(ServerFailure(message: e.message ?? 'Retry failed', statusCode: e.statusCode));
      return;
    } catch (e) {
      yield left(UnknownFailure(message: e.toString()));
      return;
    }

    await localDataSource.save(current);
    yield right(current);

    if (current.isTerminal) return;
    yield* _pollStatus(current);
  }

  @override
  Future<Either<Failure, LayerUpload>> getStatus(String uploadId) async {
    try {
      final local = await localDataSource.getById(uploadId);
      if (local == null) {
        return left(ServerFailure(message: 'No local record for upload $uploadId'));
      }
      final json = await remoteDataSource.getStatus(uploadId);
      final merged = local.mergeStatusResponse(json);
      await localDataSource.save(merged);
      return right(merged);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on TimeoutException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'Request timed out'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LayerUpload>> cancelUpload(String uploadId) async {
    final local = await localDataSource.getById(uploadId);
    if (local == null) {
      return left(ServerFailure(message: 'No local record for upload $uploadId'));
    }
    try {
      // cancel() already swallows the documented always-500 response
      // (ADR 0002) — any exception here is a genuine failure.
      await remoteDataSource.cancel(uploadId);
      final json = await remoteDataSource.getStatus(uploadId);
      final merged = local.mergeStatusResponse(json);
      await localDataSource.save(merged);
      if (merged.status != LayerUploadStatus.cancelled) {
        return left(ServerFailure(
          message: 'Cancel did not take effect (status: ${merged.status.name})',
        ));
      }
      return right(merged);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on TimeoutException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'Request timed out'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> discardUpload(String uploadId) async {
    try {
      await remoteDataSource.cancel(uploadId);
    } catch (_) {
      // Best-effort — the local record is removed regardless.
    }
    await localDataSource.delete(uploadId);
    return right(unit);
  }

  @override
  Future<Either<Failure, List<LayerUpload>>> getResumableUploads() async {
    final all = await localDataSource.getResumable();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return right(all);
  }

  @override
  Future<Either<Failure, Unit>> publishToGeoserver(String uploadId) async {
    try {
      await remoteDataSource.publishToGeoserver(uploadId);
      return right(unit);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on TimeoutException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'Request timed out'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Shared tail of the pipeline: send any remaining chunks, then finalize
  /// and poll. Used by both a fresh upload and a resumed one.
  Stream<Either<Failure, LayerUpload>> _runPipeline(LayerUploadModel upload) async* {
    var current = upload;

    if (!current.isFullyUploaded) {
      await for (final event in _sendRemainingChunks(current)) {
        final failure = event.fold((f) => f, (_) => null);
        if (failure != null) {
          yield event;
          return;
        }
        current = event.fold((_) => current, (u) => LayerUploadModel.fromEntity(u));
        await localDataSource.save(current);
        yield right(current);
      }
    }

    if (current.status != LayerUploadStatus.uploaded &&
        current.status != LayerUploadStatus.processing &&
        !current.isTerminal) {
      current = LayerUploadModel.fromEntity(
        current.copyWith(status: LayerUploadStatus.uploaded),
      );
    }

    // If a prior session already kicked off finalization (status synced as
    // `processing` from GET /status during resumeUpload), calling /tile or
    // /save again would re-trigger finalization server-side. Skip straight
    // to polling instead.
    if (current.status != LayerUploadStatus.processing && !current.isTerminal) {
      try {
        final json = current.outputFormat == LayerOutputFormat.raster
            ? await remoteDataSource.triggerTile(uploadId: current.uploadId)
            : await remoteDataSource.saveGeojson(current.uploadId);
        current = current.mergeFinalizeResponse(json);
      } on NetworkException catch (e) {
        yield left(NetworkFailure(message: e.message ?? 'No internet connection'));
        return;
      } on TimeoutException catch (e) {
        yield left(NetworkFailure(message: e.message ?? 'Request timed out'));
        return;
      } on ServerException catch (e) {
        // Known issue for raster (ADR 0002): /tile currently 500s server-side
        // without ever setting a failed status. Surface it as a failure but
        // leave the persisted record as-is (still resumable/retriable) rather
        // than marking it terminal ourselves.
        yield left(ServerFailure(message: e.message ?? 'Finalize failed', statusCode: e.statusCode));
        return;
      } catch (e) {
        yield left(UnknownFailure(message: e.toString()));
        return;
      }

      await localDataSource.save(current);
      yield right(current);
    }

    if (current.isTerminal) return;
    yield* _pollStatus(current);
  }

  Stream<Either<Failure, LayerUpload>> _pollStatus(LayerUploadModel upload) async* {
    var current = upload;
    var attempts = 0;
    while (!current.isTerminal) {
      if (attempts >= maxPollAttempts) {
        yield left(const ServerFailure(message: 'Timed out waiting for finalization to complete'));
        return;
      }
      attempts++;
      await Future<void>.delayed(statusPollInterval);
      try {
        final json = await remoteDataSource.getStatus(current.uploadId);
        current = current.mergeStatusResponse(json);
      } on NetworkException catch (e) {
        yield left(NetworkFailure(message: e.message ?? 'No internet connection'));
        return;
      } on TimeoutException catch (e) {
        yield left(NetworkFailure(message: e.message ?? 'Request timed out'));
        return;
      } on ServerException catch (e) {
        yield left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
        return;
      } catch (e) {
        yield left(UnknownFailure(message: e.toString()));
        return;
      }
      await localDataSource.save(current);
      yield right(current);
    }
  }

  /// Sends every not-yet-uploaded chunk in fixed-size batches of
  /// [maxConcurrentChunks]. Each chunk retries independently up to
  /// [maxChunkRetries] times with exponential backoff.
  ///
  /// Every chunk in a batch is started from the same pre-batch snapshot of
  /// `current` (since all batch members are dispatched together via
  /// `Future.wait`), so each chunk's returned model only reflects its own
  /// index merged into that shared snapshot — not its batch-mates'. Results
  /// are therefore folded one at a time, *unioning* each successful chunk's
  /// newly-confirmed index into the running `current` (rather than replacing
  /// `current` outright), so a later chunk's result can never erase an
  /// earlier sibling's success. If any chunk in the batch exhausts its
  /// retries, the successful siblings already folded in are still
  /// saved/yielded before the failure is yielded and the stream stops — no
  /// further batches start.
  Stream<Either<Failure, LayerUpload>> _sendRemainingChunks(
    LayerUploadModel upload,
  ) async* {
    var current = upload;
    final pending = upload.pendingChunkIndexes();

    for (var i = 0; i < pending.length; i += maxConcurrentChunks) {
      final batch = pending.skip(i).take(maxConcurrentChunks).toList();
      final results = await Future.wait([
        for (final index in batch) _sendOneChunkWithRetry(current, index),
      ]);

      Failure? batchFailure;
      for (final result in results) {
        final failure = result.fold((f) => f, (_) => null);
        if (failure != null) {
          batchFailure ??= failure;
          continue;
        }
        final succeeded = result.fold((_) => null, (u) => u)!;
        current = LayerUploadModel.fromEntity(
          current.copyWith(
            uploadedChunkIndexes: {
              ...current.uploadedChunkIndexes,
              ...succeeded.uploadedChunkIndexes,
            },
            status: succeeded.status,
            tileUrlTemplate: succeeded.tileUrlTemplate,
            updatedAt: succeeded.updatedAt,
          ),
        );
        await localDataSource.save(current);
        yield right(current);
      }

      if (batchFailure != null) {
        yield left(batchFailure);
        return;
      }
    }
  }

  Future<Either<Failure, LayerUploadModel>> _sendOneChunkWithRetry(
    LayerUploadModel upload,
    int chunkIndex,
  ) async {
    // Not transient/retryable: if the source file was purged from cache or
    // deleted by the user between sessions, no amount of retrying will help.
    if (!File(upload.filePath).existsSync()) {
      return left(ValidationFailure(
        message: 'Source file is no longer available: ${upload.filePath}',
      ));
    }

    var attempt = 0;
    while (true) {
      try {
        final bytes = await _readChunk(
          upload.filePath,
          chunkIndex,
          upload.chunkSize,
          upload.totalSize,
        );
        final json = await remoteDataSource.sendChunk(
          uploadId: upload.uploadId,
          chunkIndex: chunkIndex,
          bytes: bytes,
        );
        return right(upload.mergeChunkResponse(json, chunkIndex: chunkIndex));
      } on NetworkException catch (e) {
        attempt++;
        if (attempt > maxChunkRetries) {
          return left(NetworkFailure(message: e.message ?? 'No internet connection'));
        }
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt > maxChunkRetries) {
          return left(NetworkFailure(message: e.message ?? 'Request timed out'));
        }
      } on ServerException catch (e) {
        attempt++;
        if (attempt > maxChunkRetries) {
          return left(ServerFailure(message: e.message ?? 'Chunk upload failed', statusCode: e.statusCode));
        }
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
      final delay = chunkRetryInitialDelay * math.pow(2, attempt - 1);
      await Future<void>.delayed(delay);
    }
  }

  Future<Uint8List> _readChunk(
    String filePath,
    int chunkIndex,
    int chunkSize,
    int totalSize,
  ) async {
    final start = chunkIndex * chunkSize;
    final end = math.min(start + chunkSize, totalSize);
    final builder = BytesBuilder(copy: false);
    await for (final part in File(filePath).openRead(start, end)) {
      builder.add(part);
    }
    return builder.takeBytes();
  }
}
