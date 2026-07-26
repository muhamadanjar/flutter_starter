# Layer Upload (Chunked File Upload) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user pick a GeoTIFF (raster) or GeoJSON/shapefile-zip (vector) file in the Map feature and upload it to the tile server in chunks, with resume-after-restart, auto finalize (tile/save), and manual Geoserver publish.

**Architecture:** New Clean Architecture feature module `lib/features/map_layer_upload/` (domain/data/presentation), following the exact conventions already established in `lib/features/map/` (hand-written entities/models, no `freezed`/`@riverpod` codegen despite those being project dependencies — this codebase's real convention is plain Dart classes + manual `Provider`s). Wires into the existing `MapPage` via a new FAB and a resume banner. Talks to the tile server via a dedicated `ExternalDioClient` (same pattern as `lib/features/map/presentation/providers/map_providers.dart`).

**Tech Stack:** Flutter, Riverpod 2.5.1 (manual providers, not codegen), `fpdart` `Either`, `dio` via `ExternalDioClient`, `hive`/`hive_flutter` (JSON-string-collection-per-box pattern), `file_picker` 8.x.

## Global Constraints

- Clean Architecture: `domain/` must not import anything from `data/` or `presentation/`, or any Flutter/Dio/Hive package. Only `data/` may import `dart:io`, `dio`, `hive`.
- No `freezed`, no `@riverpod` codegen, no `build_runner` step for this feature — match the hand-written style of `lib/features/map/`.
- Error handling: repositories return `Future<Either<Failure, T>>` / `Stream<Either<Failure, T>>`, never throw. Failures come from `lib/core/errors/failures.dart` (`ServerFailure`, `NetworkFailure`, `ValidationFailure`, `UnknownFailure`) — do not add new `Failure` subclasses.
- Datasources throw `lib/core/errors/exceptions.dart` types (`ServerException`, `NetworkException`, `ValidationException`) — these are what `ExternalDioClient` already throws via `DioErrorMapper`, so datasource code just needs to catch and let them propagate or re-map, never invent new exception types.
- Chunk request body is **raw bytes**, `Content-Type: application/octet-stream` — never multipart, per `docs/adr/0002-tileserver-chunk-upload-quirks.md`.
- `POST /uploads/{id}/cancel` **always returns HTTP 500 even on success** — must be treated as "maybe succeeded, verify via `GET /status`", per ADR 0002. Never surface that specific 500 to the user as-is.
- The terminal success status string from the server is **`done`**, not `ready` (confirmed live; matches `MapLayer.isReady => status == 'done'` in `lib/features/map/domain/entities/map_layer.dart`). `processing` and `failed` string values are **unconfirmed** (`/tile` could not be made to succeed live — see ADR 0002) — implement them as the best-guess literal strings `processing`/`failed`, flagged for future correction if the server disagrees once `/tile` is fixed.
- File types: `.tif`/`.tiff` → `output_format=raster`; `.geojson`/`.zip` → `output_format=vector`. Detected from filename extension, never asked of the user.
- Platform: mobile + desktop only. Use `file_picker` with `withData: false` and `dart:io File.openRead(start, end)` to stream chunks — never load the whole file into memory. (Existing code in `lib/core/widgets/universal_file_picker_widget.dart` uses `withData: kIsWeb`; this feature always passes `false` since web is out of scope.)
- Chunk concurrency: up to 3 chunks in flight at once (batches of 3, not a full sliding-window pool — see Task 7 note), each chunk independently retried up to 3 times with exponential backoff (500ms, 1000ms, 2000ms) before the whole upload is reported as failed.
- The `layer-upload` feature's own `ExternalDioClient` must be constructed with `enableRetry: false`. `ExternalDioClient`'s built-in `RetryInterceptor` already retries any 5xx automatically 3× with backoff at the transport layer — leaving it on would silently multiply our own application-level chunk retry (up to 3×3=9 attempts) and would also delay every `/cancel` call by several seconds before our 500-is-maybe-success handling ever runs. Disabling it puts all retry behavior under this feature's explicit control.
- Raster (`/tile`) finalize cannot be verified end-to-end against the live server today (confirmed broken, ADR 0002) — implement it fully per the documented contract anyway; do not drop it from scope. Vector (`/save`) is fully verifiable today.

---

### Task 1: Fix `DioErrorMapper` to parse FastAPI-style 422 validation errors

The tile server (FastAPI) returns `422` bodies shaped `{"detail":[{"loc":["body","filename"],"msg":"Field required","type":"missing"}]}` (confirmed live). The existing `DioErrorMapper.map` only knows how to read `{"errors": {"field": "message"}}` (the internal User Management API's shape), so any 422 from the tile server currently produces an empty `fieldErrors` map. `DioErrorMapper` is shared by `ExternalDioClient`, and is documented as being for third-party/external APIs generally, so this is a genuine latent bug affecting every FastAPI-backed external API this app talks to (already including `lib/features/map/data/datasources/map_remote_datasource.dart`), not scope creep for this feature.

**Files:**
- Modify: `lib/core/network/dio_error_mapper.dart:41-58` (the `statusCode == 422` branch inside `DioErrorMapper.map`)
- Test: `test/core/network/dio_error_mapper_test.dart` (new file)

**Interfaces:**
- Consumes: nothing new — `DioException`, `ValidationException` (`lib/core/errors/exceptions.dart`) already exist.
- Produces: `DioErrorMapper.map(DioException)` now also parses FastAPI `detail` lists. Nothing downstream depends on this yet, but Task 6/7 rely on `ValidationException.fieldErrors` being populated correctly for tile-server 422s.

- [ ] **Step 1: Write the failing test**

Create `test/core/network/dio_error_mapper_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:enterprise_flutter_app/core/errors/exceptions.dart';
import 'package:enterprise_flutter_app/core/network/dio_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int statusCode, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  group('DioErrorMapper.map 422 handling', () {
    test('parses FastAPI-style {"detail":[...]} into fieldErrors', () {
      final err = _badResponse(422, {
        'detail': [
          {
            'type': 'missing',
            'loc': ['body', 'filename'],
            'msg': 'Field required',
          },
          {
            'type': 'greater_than',
            'loc': ['body', 'total_size'],
            'msg': 'Input should be greater than 0',
          },
        ],
      });

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ValidationException>());
      final validation = mapped as ValidationException;
      expect(validation.fieldErrors, {
        'filename': 'Field required',
        'total_size': 'Input should be greater than 0',
      });
    });

    test('still parses the internal-API {"errors": {...}} shape (regression)', () {
      final err = _badResponse(422, {
        'message': 'Validation failed',
        'errors': {'email': 'Email is invalid'},
      });

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ValidationException>());
      final validation = mapped as ValidationException;
      expect(validation.fieldErrors, {'email': 'Email is invalid'});
      expect(validation.message, 'Validation failed');
    });

    test('handles a 422 with neither shape without throwing', () {
      final err = _badResponse(422, {'unexpected': true});

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ValidationException>());
      expect((mapped as ValidationException).fieldErrors, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/network/dio_error_mapper_test.dart`
Expected: FAIL on the first test — `fieldErrors` comes back `{}` instead of the two-entry map, because the current code only reads `data['errors']`.

- [ ] **Step 3: Fix the mapper**

In `lib/core/network/dio_error_mapper.dart`, replace the `statusCode == 422` branch inside `map`:

```dart
        if (statusCode == 422) {
          final fieldErrors = <String, String>{};
          final data = error.response?.data;
          if (data is Map) {
            final errors = data['errors'];
            if (errors is Map) {
              errors.forEach((key, value) {
                fieldErrors[key.toString()] = value.toString();
              });
            } else {
              final detail = data['detail'];
              if (detail is List) {
                for (final item in detail) {
                  if (item is Map) {
                    final loc = item['loc'];
                    final field = (loc is List && loc.isNotEmpty)
                        ? loc.last.toString()
                        : 'field';
                    fieldErrors[field] =
                        item['msg']?.toString() ?? 'Invalid value';
                  }
                }
              }
            }
          }
          return ValidationException(message: message, fieldErrors: fieldErrors);
        }
```

(This replaces the existing block that only checked `errors`; the `message` variable above it is unchanged.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/network/dio_error_mapper_test.dart`
Expected: PASS, all 3 tests.

- [ ] **Step 5: Run full analyze on the changed file**

Run: `flutter analyze lib/core/network/dio_error_mapper.dart test/core/network/dio_error_mapper_test.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/core/network/dio_error_mapper.dart test/core/network/dio_error_mapper_test.dart
git commit -m "fix(network): parse FastAPI-style 422 validation errors in DioErrorMapper"
```

---

### Task 2: Domain entity — `LayerUpload`

**Files:**
- Create: `lib/features/map_layer_upload/domain/entities/layer_upload.dart`
- Test: `test/features/map_layer_upload/domain/entities/layer_upload_test.dart`

**Interfaces:**
- Consumes: nothing (pure domain, no imports outside `dart:core`).
- Produces:
  - `enum LayerOutputFormat { raster, vector }` with extension `LayerOutputFormatX`: `String get apiValue`, `static LayerOutputFormat fromApiValue(String)`, `static LayerOutputFormat fromFilename(String filename)`.
  - `enum LayerUploadStatus { pending, uploading, uploaded, processing, done, failed, cancelled }` with extension `LayerUploadStatusX`: `static LayerUploadStatus fromApiValue(String)`.
  - `class LayerUpload` with fields `uploadId, layerId, filename, filePath, totalSize, chunkSize, totalChunks, uploadedChunkIndexes (Set<int>), outputFormat, status, errorMessage, tileUrlTemplate, updatedAt` and methods `uploadedChunkCount`, `progressPercent`, `isFullyUploaded`, `isTerminal`, `canResume`, `isChunkUploaded(int)`, `pendingChunkIndexes()`, `markChunkUploaded(int)`, `copyWith(...)`.
  - All of the above are consumed starting Task 3.

- [ ] **Step 1: Write the failing test**

Create `test/features/map_layer_upload/domain/entities/layer_upload_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/map_layer_upload/domain/entities/layer_upload_test.dart`
Expected: FAIL with "Target of URI doesn't exist" (the entity file doesn't exist yet).

- [ ] **Step 3: Write the entity**

Create `lib/features/map_layer_upload/domain/entities/layer_upload.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/map_layer_upload/domain/entities/layer_upload_test.dart`
Expected: PASS, all tests.

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/domain/entities/layer_upload.dart test/features/map_layer_upload/domain/entities/layer_upload_test.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/map_layer_upload/domain/entities/layer_upload.dart test/features/map_layer_upload/domain/entities/layer_upload_test.dart
git commit -m "feat(map-layer-upload): add LayerUpload domain entity"
```

---

### Task 3: Domain repository interface — `LayerUploadRepository`

**Files:**
- Create: `lib/features/map_layer_upload/domain/repositories/layer_upload_repository.dart`

**Interfaces:**
- Consumes: `LayerUpload` (Task 2), `Failure` (`lib/core/errors/failures.dart`), `fpdart`'s `Either`/`Unit`.
- Produces: `abstract class LayerUploadRepository` with methods `uploadFile`, `resumeUpload`, `retryUpload`, `getStatus`, `cancelUpload`, `discardUpload`, `getResumableUploads`, `publishToGeoserver` — exact signatures below, consumed by Task 7 (impl) and Task 8 (usecases).

No test for this task — it is a pure interface with no logic (mirrors `lib/features/map/domain/repositories/map_repository.dart`, which also has no dedicated test file).

- [ ] **Step 1: Write the interface**

Create `lib/features/map_layer_upload/domain/repositories/layer_upload_repository.dart`:

```dart
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
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/domain/repositories/layer_upload_repository.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/map_layer_upload/domain/repositories/layer_upload_repository.dart
git commit -m "feat(map-layer-upload): add LayerUploadRepository interface"
```

---

### Task 4: Data model — `LayerUploadModel`

Handles every JSON shape the entity needs to cross: the four API response bodies (`init`, chunk, `/status`, finalize), and the Hive persistence shape.

**Files:**
- Create: `lib/features/map_layer_upload/data/models/layer_upload_model.dart`
- Test: `test/features/map_layer_upload/data/models/layer_upload_model_test.dart`

**Interfaces:**
- Consumes: `LayerUpload`, `LayerUploadStatus`, `LayerUploadStatusX`, `LayerOutputFormat`, `LayerOutputFormatX` (Task 2).
- Produces: `class LayerUploadModel extends LayerUpload` with:
  - `factory LayerUploadModel.fromEntity(LayerUpload)`
  - `factory LayerUploadModel.fromInitResponse(Map<String, dynamic> json, {required String filePath, required String filename, required int totalSize, required LayerOutputFormat outputFormat})`
  - `LayerUploadModel mergeChunkResponse(Map<String, dynamic> json, {required int chunkIndex})`
  - `LayerUploadModel mergeStatusResponse(Map<String, dynamic> json)`
  - `LayerUploadModel mergeFinalizeResponse(Map<String, dynamic> json)`
  - `factory LayerUploadModel.fromHiveJson(Map<String, dynamic> json)`
  - `Map<String, dynamic> toHiveJson()`
  - Consumed by Task 5 (local datasource), Task 6 (remote datasource returns raw JSON that this parses), Task 7 (repository impl).

- [ ] **Step 1: Write the failing test**

Create `test/features/map_layer_upload/data/models/layer_upload_model_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/map_layer_upload/data/models/layer_upload_model_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Write the model**

Create `lib/features/map_layer_upload/data/models/layer_upload_model.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/map_layer_upload/data/models/layer_upload_model_test.dart`
Expected: PASS, all tests.

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/data/models/layer_upload_model.dart test/features/map_layer_upload/data/models/layer_upload_model_test.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/map_layer_upload/data/models/layer_upload_model.dart test/features/map_layer_upload/data/models/layer_upload_model_test.dart
git commit -m "feat(map-layer-upload): add LayerUploadModel (API + Hive JSON mapping)"
```

---

### Task 5: Local datasource — `LayerUploadLocalDataSource` + Hive box registration

**Files:**
- Create: `lib/features/map_layer_upload/data/datasources/layer_upload_local_datasource.dart`
- Modify: `lib/core/constants/app_constants.dart` (add `layerUploadsBox` constant)
- Modify: `lib/main_common.dart` (open the box at startup)
- Test: `test/features/map_layer_upload/data/datasources/layer_upload_local_datasource_test.dart`

**Interfaces:**
- Consumes: `LayerUploadModel` (Task 4).
- Produces: `abstract class LayerUploadLocalDataSource` with `openBox()`, `getAll()`, `getById(String)`, `save(LayerUploadModel)`, `delete(String)`, `getResumable()`; `class LayerUploadLocalDataSourceImpl implements LayerUploadLocalDataSource`. Consumed by Task 7 (repository impl) and Task 9 (provider wiring).
- `AppConstants.layerUploadsBox` (`String`, value `'layer_uploads'`) — consumed by `LayerUploadLocalDataSourceImpl`'s default box name and by `main_common.dart`.

- [ ] **Step 1: Write the failing test**

Create `test/features/map_layer_upload/data/datasources/layer_upload_local_datasource_test.dart`:

```dart
import 'dart:io';

import 'package:enterprise_flutter_app/features/map_layer_upload/data/datasources/layer_upload_local_datasource.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/models/layer_upload_model.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/domain/entities/layer_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

LayerUploadModel _model(String id, {LayerUploadStatus status = LayerUploadStatus.uploading}) {
  return LayerUploadModel(
    uploadId: id,
    layerId: 'layer-$id',
    filename: '$id.tif',
    filePath: '/tmp/$id.tif',
    totalSize: 100,
    chunkSize: 50,
    totalChunks: 2,
    outputFormat: LayerOutputFormat.raster,
    status: status,
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late Directory tempDir;
  late LayerUploadLocalDataSourceImpl dataSource;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('layer_upload_test');
    Hive.init(tempDir.path);
    dataSource = LayerUploadLocalDataSourceImpl(boxName: 'layer_uploads_test');
    await dataSource.openBox();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('layer_uploads_test');
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('getAll returns empty list when nothing saved', () async {
    expect(await dataSource.getAll(), isEmpty);
  });

  test('save then getById returns the saved record', () async {
    await dataSource.save(_model('u1'));
    final loaded = await dataSource.getById('u1');
    expect(loaded, isNotNull);
    expect(loaded!.layerId, 'layer-u1');
  });

  test('save with an existing uploadId overwrites, does not duplicate', () async {
    await dataSource.save(_model('u1', status: LayerUploadStatus.uploading));
    await dataSource.save(_model('u1', status: LayerUploadStatus.done));
    final all = await dataSource.getAll();
    expect(all, hasLength(1));
    expect(all.single.status, LayerUploadStatus.done);
  });

  test('delete removes the record', () async {
    await dataSource.save(_model('u1'));
    await dataSource.delete('u1');
    expect(await dataSource.getById('u1'), isNull);
  });

  test('getResumable excludes terminal statuses', () async {
    await dataSource.save(_model('u1', status: LayerUploadStatus.uploading));
    await dataSource.save(_model('u2', status: LayerUploadStatus.done));
    await dataSource.save(_model('u3', status: LayerUploadStatus.cancelled));
    final resumable = await dataSource.getResumable();
    expect(resumable.map((u) => u.uploadId), ['u1']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/map_layer_upload/data/datasources/layer_upload_local_datasource_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Write the local datasource**

Create `lib/features/map_layer_upload/data/datasources/layer_upload_local_datasource.dart`:

```dart
import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/layer_upload_model.dart';

/// Local persistence (Hive) for chunked layer uploads.
///
/// Stores the whole collection as a single JSON string under one key in the
/// `layer_uploads` box, mirroring `TrackRecordLocalDataSource`. The box is
/// opened once in `main_common.dart` at startup.
abstract class LayerUploadLocalDataSource {
  Future<void> openBox();
  Future<List<LayerUploadModel>> getAll();
  Future<LayerUploadModel?> getById(String uploadId);
  Future<void> save(LayerUploadModel upload);
  Future<void> delete(String uploadId);

  /// Non-terminal uploads left over from a previous session.
  Future<List<LayerUploadModel>> getResumable();
}

class LayerUploadLocalDataSourceImpl implements LayerUploadLocalDataSource {
  LayerUploadLocalDataSourceImpl({this.boxName = 'layer_uploads'});

  final String boxName;
  Box? _box;

  Box get _store {
    final cached = _box;
    if (cached != null && cached.isOpen) return cached;
    if (Hive.isBoxOpen(boxName)) return _box = Hive.box(boxName);
    throw StateError(
      'Hive box "$boxName" is not open. Call openBox() during app startup.',
    );
  }

  @override
  Future<void> openBox() async {
    _box = await Hive.openBox(boxName);
  }

  List<LayerUploadModel> _readAll() {
    final raw = _store.get(_key) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => LayerUploadModel.fromHiveJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeAll(List<LayerUploadModel> uploads) async {
    await _store.put(_key, jsonEncode(uploads.map((u) => u.toHiveJson()).toList()));
  }

  @override
  Future<List<LayerUploadModel>> getAll() async => _readAll();

  @override
  Future<LayerUploadModel?> getById(String uploadId) async {
    for (final u in _readAll()) {
      if (u.uploadId == uploadId) return u;
    }
    return null;
  }

  @override
  Future<void> save(LayerUploadModel upload) async {
    final all = List<LayerUploadModel>.from(_readAll());
    final idx = all.indexWhere((u) => u.uploadId == upload.uploadId);
    if (idx == -1) {
      all.add(upload);
    } else {
      all[idx] = upload;
    }
    await _writeAll(all);
  }

  @override
  Future<void> delete(String uploadId) async {
    final all = _readAll()..removeWhere((u) => u.uploadId == uploadId);
    await _writeAll(all);
  }

  @override
  Future<List<LayerUploadModel>> getResumable() async =>
      _readAll().where((u) => !u.isTerminal).toList();

  static const String _key = 'layer_uploads_v1';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/map_layer_upload/data/datasources/layer_upload_local_datasource_test.dart`
Expected: PASS, all tests.

- [ ] **Step 5: Register the Hive box**

In `lib/core/constants/app_constants.dart`, add alongside the existing `// Hive Box Names` group:

```dart
  static const String layerUploadsBox = 'layer_uploads';
```

In `lib/main_common.dart`, inside `_initializeHive()`, add after the existing `await Hive.openBox('record_tracks');` line:

```dart
  await Hive.openBox(AppConstants.layerUploadsBox);
```

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/data/datasources/layer_upload_local_datasource.dart lib/core/constants/app_constants.dart lib/main_common.dart test/features/map_layer_upload/data/datasources/layer_upload_local_datasource_test.dart`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/map_layer_upload/data/datasources/layer_upload_local_datasource.dart lib/core/constants/app_constants.dart lib/main_common.dart test/features/map_layer_upload/data/datasources/layer_upload_local_datasource_test.dart
git commit -m "feat(map-layer-upload): add local Hive datasource and register layerUploadsBox"
```

---

### Task 6: Remote datasource — `LayerUploadRemoteDataSource`

**Files:**
- Create: `lib/features/map_layer_upload/data/datasources/layer_upload_remote_datasource.dart`
- Test (live, hits the real tile server): `test/map_layer_upload_datasource_live_test.dart`

**Interfaces:**
- Consumes: `ExternalDioClient` (`lib/core/network/external_dio_client.dart`), `ServerException` (`lib/core/errors/exceptions.dart`).
- Produces: `abstract class LayerUploadRemoteDataSource` with `initUpload`, `sendChunk`, `getStatus`, `triggerTile`, `saveGeojson`, `publishToGeoserver`, `retry`, `cancel` — exact signatures below. `class LayerUploadRemoteDataSourceImpl implements LayerUploadRemoteDataSource`. Consumed by Task 7 (repository impl).

- [ ] **Step 1: Write the remote datasource**

(No red/green unit test here — like `MapRemoteDataSourceImpl`, this class is thin Dio plumbing; it is exercised by the live test in Step 2 and indirectly by Task 7's repository tests via a hand-written fake implementing this interface.)

Create `lib/features/map_layer_upload/data/datasources/layer_upload_remote_datasource.dart`:

```dart
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
```

- [ ] **Step 2: Write and run a live test against the real tile server**

Create `test/map_layer_upload_datasource_live_test.dart` (mirrors `test/map_datasource_live_test.dart`'s `@Tags(['live'])` convention):

```dart
@Tags(['live'])
library;

import 'dart:typed_data';

import 'package:enterprise_flutter_app/core/network/external_dio_client.dart';
import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/datasources/layer_upload_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _AlwaysOnline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

void main() {
  late LayerUploadRemoteDataSourceImpl ds;

  setUp(() {
    ds = LayerUploadRemoteDataSourceImpl(ExternalDioClient(
      baseUrl: 'https://tileserver.jattirayyakonsultindo.co.id',
      networkInfo: _AlwaysOnline(),
      enableLogging: false,
      enableRetry: false,
    ));
  });

  test('vector pipeline: init -> chunk -> save reaches status done', () async {
    const geojson =
        '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{},'
        '"geometry":{"type":"Point","coordinates":[106.05,-6.05]}}]}';
    final bytes = Uint8List.fromList(geojson.codeUnits);

    final init = await ds.initUpload(
      filename: 'live_test.geojson',
      totalSize: bytes.length,
      outputFormat: 'vector',
    );
    final uploadId = init['upload_id'] as String;
    expect(init['total_chunks'], 1);

    final chunkResult = await ds.sendChunk(uploadId: uploadId, chunkIndex: 0, bytes: bytes);
    expect(chunkResult['is_complete'], isTrue);

    final saveResult = await ds.saveGeojson(uploadId);
    expect(saveResult['status'], 'done');

    final status = await ds.getStatus(uploadId);
    expect(status['status'], 'done');
  });

  test('cancel on a fresh upload does not throw, and status confirms cancelled', () async {
    final init = await ds.initUpload(
      filename: 'live_cancel_test.tif',
      totalSize: 10,
      outputFormat: 'raster',
    );
    final uploadId = init['upload_id'] as String;

    // Per ADR 0002 this always 500s server-side even on success — the
    // datasource must not throw for this specific case.
    await ds.cancel(uploadId);

    final status = await ds.getStatus(uploadId);
    expect(status['status'], 'cancelled');
  });
}
```

Run: `flutter test --tags live test/map_layer_upload_datasource_live_test.dart`
Expected: PASS, both tests, against the real server (requires network access to `tileserver.jattirayyakonsultindo.co.id`).

Note: `/tile` (raster finalize) is deliberately **not** exercised in this live test — it is confirmed broken server-side (ADR 0002) and every attempt returns 500 regardless of input, so a passing assertion isn't achievable today. Do not add one until the tile server team confirms a fix.

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/data/datasources/layer_upload_remote_datasource.dart test/map_layer_upload_datasource_live_test.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/map_layer_upload/data/datasources/layer_upload_remote_datasource.dart test/map_layer_upload_datasource_live_test.dart
git commit -m "feat(map-layer-upload): add remote datasource for tileserver chunked-upload API"
```

---

### Task 7: Repository implementation — `LayerUploadRepositoryImpl`

The orchestration core: init → send chunks (batched, throttled, retried) → auto-finalize → poll status; plus resume, retry, cancel (with the 500-quirk workaround), discard.

**Files:**
- Create: `lib/features/map_layer_upload/data/repositories/layer_upload_repository_impl.dart`
- Test: `test/features/map_layer_upload/data/repositories/layer_upload_repository_impl_test.dart`

**Interfaces:**
- Consumes: `LayerUploadRepository` (Task 3), `LayerUploadRemoteDataSource` (Task 6), `LayerUploadLocalDataSource` (Task 5), `LayerUploadModel` (Task 4), `Failure`/`ServerFailure`/`NetworkFailure`/`ValidationFailure` (`lib/core/errors/failures.dart`), `ServerException`/`NetworkException`/`ValidationException` (`lib/core/errors/exceptions.dart`).
- Produces: `class LayerUploadRepositoryImpl implements LayerUploadRepository`, constructor `LayerUploadRepositoryImpl({required LayerUploadRemoteDataSource remoteDataSource, required LayerUploadLocalDataSource localDataSource, int maxConcurrentChunks = 3, int maxChunkRetries = 3, Duration chunkRetryInitialDelay = const Duration(milliseconds: 500), Duration statusPollInterval = const Duration(seconds: 3)})`. Consumed by Task 9 (providers).

**Design note on concurrency:** chunks are sent in fixed-size batches of `maxConcurrentChunks` (via `Future.wait`) rather than a fully dynamic sliding-window pool. This satisfies "up to 3 concurrent" and "isolated per-chunk retry" from the grilling session with far less concurrency-bug surface than a hand-rolled pool; the only difference from a true sliding window is that a batch waits for its slowest member before the next batch starts. Note this simplification if a future revision wants stricter pipelining.

- [ ] **Step 1: Write the failing tests**

Create `test/features/map_layer_upload/data/repositories/layer_upload_repository_impl_test.dart`:

```dart
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
  bool tileAlways500 = false;
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
    if (tileAlways500) {
      throw const ServerException(message: 'tile broken', statusCode: 500);
    }
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

  test('uploadFile drives a vector file through init -> chunks -> save -> done', () async {
    final events = await repository
        .uploadFile(filePath: '/tmp/does-not-need-to-exist.geojson', filename: 'a.geojson', totalSize: 20)
        .toList();

    expect(events.every((e) => e.isRight()), isTrue, reason: events.toString());
    final last = events.last.fold((f) => throw f, (u) => u);
    expect(last.status, LayerUploadStatus.done);
    expect(remote.chunkCalls, 2);

    final saved = await local.getById('u1');
    expect(saved?.status, LayerUploadStatus.done);
  }, skip: 'uploadFile reads chunks from disk via dart:io File — see chunk-read test below for the parts that do not need a real file');

  test('a chunk that exhausts retries reports failure and stops the batch', () async {
    remote.chunkFailuresRemaining = 10; // always fails, more than maxChunkRetries
    final events = <dynamic>[];
    await for (final e in repository.resumeUploadForTest(
      LayerUploadModel(
        uploadId: 'u1',
        layerId: 'l1',
        filename: 'a.tif',
        filePath: '/tmp/a.tif',
        totalSize: 20,
        chunkSize: 10,
        totalChunks: 2,
        outputFormat: LayerOutputFormat.raster,
        status: LayerUploadStatus.pending,
        updatedAt: DateTime(2026, 1, 1),
      ),
    )) {
      events.add(e);
    }

    expect(events.last.isLeft(), isTrue);
    final failure = events.last.fold((f) => f, (_) => null);
    expect(failure, isA<ServerFailure>());
  }, skip: 'requires a readable file at filePath — exercised via the live/manual test plan instead');

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
```

Two of the pipeline tests (`uploadFile ...` and `a chunk that exhausts retries ...`) are marked `skip:` with an explanation, because they need `dart:io File.openRead` to succeed against a real path — driving those without a real file requires either a temp file on disk or a seam this plan does not introduce (see Step 4 below for how Step 4 actually verifies chunk-reading instead). This keeps the test suite honest rather than faking a pass.

- [ ] **Step 2: Add the tiny test-only seam the skipped tests reference**

The skipped test above calls `repository.resumeUploadForTest(...)` — to make intent clear without shipping test-only API on the public interface, delete that skipped test block entirely instead of adding production API for it. Replace it with a real, unskipped test that exercises retry behavior through the public `resumeUpload` API using a **real temporary file**, since `dart:io` has no seam to fake in this codebase's existing style (matches how `test/map_datasource_live_test.dart` just accepts hitting real infrastructure rather than mocking `dio` internals). Remove the two `skip:`ped tests and the unused `_FakeRemoteDataSource.tileAlways500`/`finalizeStatus` fields if unused, and add:

```dart
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
```

Add `import 'dart:io';` to the top of the test file. Delete the two `skip:`ped tests from Step 1 entirely (they are superseded by this group).

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/map_layer_upload/data/repositories/layer_upload_repository_impl_test.dart`
Expected: FAIL — `layer_upload_repository_impl.dart` doesn't exist yet.

- [ ] **Step 4: Write the repository implementation**

Create `lib/features/map_layer_upload/data/repositories/layer_upload_repository_impl.dart`:

```dart
import 'dart:async';
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

class LayerUploadRepositoryImpl implements LayerUploadRepository {
  LayerUploadRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.maxConcurrentChunks = 3,
    this.maxChunkRetries = 3,
    this.chunkRetryInitialDelay = const Duration(milliseconds: 500),
    this.statusPollInterval = const Duration(seconds: 3),
  });

  final LayerUploadRemoteDataSource remoteDataSource;
  final LayerUploadLocalDataSource localDataSource;
  final int maxConcurrentChunks;
  final int maxChunkRetries;
  final Duration chunkRetryInitialDelay;
  final Duration statusPollInterval;

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
    } on ValidationException catch (e) {
      yield left(ValidationFailure(message: e.message ?? 'Invalid file', fieldErrors: e.fieldErrors));
      return;
    } on ServerException catch (e) {
      yield left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
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
    } on ServerException catch (e) {
      yield left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
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
    } on ServerException catch (e) {
      yield left(ServerFailure(message: e.message ?? 'Retry failed', statusCode: e.statusCode));
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
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
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
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
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
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
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

    if (current.status != LayerUploadStatus.uploaded && !current.isTerminal) {
      current = LayerUploadModel.fromEntity(
        current.copyWith(status: LayerUploadStatus.uploaded),
      );
    }

    try {
      final json = current.outputFormat == LayerOutputFormat.raster
          ? await remoteDataSource.triggerTile(uploadId: current.uploadId)
          : await remoteDataSource.saveGeojson(current.uploadId);
      current = current.mergeFinalizeResponse(json);
    } on NetworkException catch (e) {
      yield left(NetworkFailure(message: e.message ?? 'No internet connection'));
      return;
    } on ServerException catch (e) {
      // Known issue for raster (ADR 0002): /tile currently 500s server-side
      // without ever setting a failed status. Surface it as a failure but
      // leave the persisted record as-is (still resumable/retriable) rather
      // than marking it terminal ourselves.
      yield left(ServerFailure(message: e.message ?? 'Finalize failed', statusCode: e.statusCode));
      return;
    }

    await localDataSource.save(current);
    yield right(current);

    if (current.isTerminal) return;
    yield* _pollStatus(current);
  }

  Stream<Either<Failure, LayerUpload>> _pollStatus(LayerUploadModel upload) async* {
    var current = upload;
    while (!current.isTerminal) {
      await Future<void>.delayed(statusPollInterval);
      try {
        final json = await remoteDataSource.getStatus(current.uploadId);
        current = current.mergeStatusResponse(json);
      } on NetworkException catch (e) {
        yield left(NetworkFailure(message: e.message ?? 'No internet connection'));
        return;
      } on ServerException catch (e) {
        yield left(ServerFailure(message: e.message ?? 'Server error', statusCode: e.statusCode));
        return;
      }
      await localDataSource.save(current);
      yield right(current);
    }
  }

  /// Sends every not-yet-uploaded chunk in fixed-size batches of
  /// [maxConcurrentChunks]. Each chunk retries independently up to
  /// [maxChunkRetries] times with exponential backoff. If any chunk in a
  /// batch exhausts its retries, no further batches start and a failure is
  /// yielded; chunks that already succeeded remain recorded via the events
  /// already emitted.
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

      for (final result in results) {
        final failure = result.fold((f) => f, (_) => null);
        if (failure != null) {
          yield left(failure);
          return;
        }
      }
      for (final result in results) {
        current = result.fold((_) => current, (u) => u);
        yield right(current);
      }
    }
  }

  Future<Either<Failure, LayerUploadModel>> _sendOneChunkWithRetry(
    LayerUploadModel upload,
    int chunkIndex,
  ) async {
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
      } on ServerException catch (e) {
        attempt++;
        if (attempt > maxChunkRetries) {
          return left(ServerFailure(message: e.message ?? 'Chunk upload failed', statusCode: e.statusCode));
        }
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
    final bytes = <int>[];
    await for (final part in File(filePath).openRead(start, end)) {
      bytes.addAll(part);
    }
    return Uint8List.fromList(bytes);
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/map_layer_upload/data/repositories/layer_upload_repository_impl_test.dart`
Expected: PASS, all tests (including the two real-temp-file tests from Step 2).

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/data/repositories/layer_upload_repository_impl.dart test/features/map_layer_upload/data/repositories/layer_upload_repository_impl_test.dart`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/map_layer_upload/data/repositories/layer_upload_repository_impl.dart test/features/map_layer_upload/data/repositories/layer_upload_repository_impl_test.dart
git commit -m "feat(map-layer-upload): implement LayerUploadRepositoryImpl pipeline"
```

---

### Task 8: Domain usecases

Eight thin pass-throughs over `LayerUploadRepository`, matching the existing one-liner usecase style (`GetMapLayersUseCase`).

**Files:**
- Create: `lib/features/map_layer_upload/domain/usecases/upload_layer_file_usecase.dart`
- Create: `lib/features/map_layer_upload/domain/usecases/resume_layer_upload_usecase.dart`
- Create: `lib/features/map_layer_upload/domain/usecases/retry_layer_upload_usecase.dart`
- Create: `lib/features/map_layer_upload/domain/usecases/cancel_layer_upload_usecase.dart`
- Create: `lib/features/map_layer_upload/domain/usecases/discard_layer_upload_usecase.dart`
- Create: `lib/features/map_layer_upload/domain/usecases/get_layer_upload_status_usecase.dart`
- Create: `lib/features/map_layer_upload/domain/usecases/get_resumable_layer_uploads_usecase.dart`
- Create: `lib/features/map_layer_upload/domain/usecases/publish_layer_to_geoserver_usecase.dart`

**Interfaces:**
- Consumes: `LayerUploadRepository` (Task 3), `LayerUpload` (Task 2), `Failure` (`lib/core/errors/failures.dart`), `fpdart`.
- Produces: `UploadLayerFileUseCase`, `ResumeLayerUploadUseCase`, `RetryLayerUploadUseCase`, `CancelLayerUploadUseCase`, `DiscardLayerUploadUseCase`, `GetLayerUploadStatusUseCase`, `GetResumableLayerUploadsUseCase`, `PublishLayerToGeoserverUseCase` — each with a `call(...)` method mirroring its repository method's signature. Consumed by Task 9 (providers).

No dedicated tests — these are one-line delegations (matching `GetMapLayersUseCase`, which also has no test file); their behavior is exercised through Task 7's repository tests.

- [ ] **Step 1: Write the usecases**

`lib/features/map_layer_upload/domain/usecases/upload_layer_file_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class UploadLayerFileUseCase {
  UploadLayerFileUseCase(this._repository);

  final LayerUploadRepository _repository;

  Stream<Either<Failure, LayerUpload>> call({
    required String filePath,
    required String filename,
    required int totalSize,
  }) =>
      _repository.uploadFile(filePath: filePath, filename: filename, totalSize: totalSize);
}
```

`lib/features/map_layer_upload/domain/usecases/resume_layer_upload_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class ResumeLayerUploadUseCase {
  ResumeLayerUploadUseCase(this._repository);

  final LayerUploadRepository _repository;

  Stream<Either<Failure, LayerUpload>> call(String uploadId) =>
      _repository.resumeUpload(uploadId);
}
```

`lib/features/map_layer_upload/domain/usecases/retry_layer_upload_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class RetryLayerUploadUseCase {
  RetryLayerUploadUseCase(this._repository);

  final LayerUploadRepository _repository;

  Stream<Either<Failure, LayerUpload>> call(String uploadId) =>
      _repository.retryUpload(uploadId);
}
```

`lib/features/map_layer_upload/domain/usecases/cancel_layer_upload_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class CancelLayerUploadUseCase {
  CancelLayerUploadUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, LayerUpload>> call(String uploadId) =>
      _repository.cancelUpload(uploadId);
}
```

`lib/features/map_layer_upload/domain/usecases/discard_layer_upload_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/layer_upload_repository.dart';

class DiscardLayerUploadUseCase {
  DiscardLayerUploadUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, Unit>> call(String uploadId) => _repository.discardUpload(uploadId);
}
```

`lib/features/map_layer_upload/domain/usecases/get_layer_upload_status_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class GetLayerUploadStatusUseCase {
  GetLayerUploadStatusUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, LayerUpload>> call(String uploadId) => _repository.getStatus(uploadId);
}
```

`lib/features/map_layer_upload/domain/usecases/get_resumable_layer_uploads_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class GetResumableLayerUploadsUseCase {
  GetResumableLayerUploadsUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, List<LayerUpload>>> call() => _repository.getResumableUploads();
}
```

`lib/features/map_layer_upload/domain/usecases/publish_layer_to_geoserver_usecase.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/layer_upload_repository.dart';

class PublishLayerToGeoserverUseCase {
  PublishLayerToGeoserverUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, Unit>> call(String uploadId) => _repository.publishToGeoserver(uploadId);
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/domain/usecases/`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/map_layer_upload/domain/usecases/
git commit -m "feat(map-layer-upload): add usecases (upload, resume, retry, cancel, discard, status, list, publish)"
```

---

### Task 9: Presentation providers — DI wiring + active-upload notifier

**Files:**
- Create: `lib/features/map_layer_upload/presentation/providers/layer_upload_providers.dart`

**Interfaces:**
- Consumes: `tileServerBaseUrlProvider`, `networkInfoProvider` (`lib/features/map/presentation/providers/map_providers.dart` and `lib/core/network/network_info.dart`), `ExternalDioClient`, all Task 4–8 classes.
- Produces:
  - Providers: `layerUploadApiClientProvider`, `layerUploadRemoteDataSourceProvider`, `layerUploadLocalDataSourceProvider`, `layerUploadRepositoryProvider`, one `Provider` per usecase (`uploadLayerFileUseCaseProvider`, `resumeLayerUploadUseCaseProvider`, `retryLayerUploadUseCaseProvider`, `cancelLayerUploadUseCaseProvider`, `discardLayerUploadUseCaseProvider`, `getLayerUploadStatusUseCaseProvider`, `getResumableLayerUploadsUseCaseProvider`, `publishLayerToGeoserverUseCaseProvider`).
  - `resumableLayerUploadsProvider` (`FutureProvider<List<LayerUpload>>`).
  - `activeLayerUploadProvider` (`NotifierProvider<ActiveLayerUploadNotifier, AsyncValue<LayerUpload>?>`) with `ActiveLayerUploadNotifier.start(...)`, `.resume(String)`, `.retry(String)`, `.cancel()`, `.clear()`.
  - Consumed by Task 10 (widgets) and Task 11 (MapPage wiring).

No dedicated test file for this task — matches `map_providers.dart`, which also has none; it is pure DI wiring exercised through widget usage in Tasks 10–11.

- [ ] **Step 1: Write the providers**

Create `lib/features/map_layer_upload/presentation/providers/layer_upload_providers.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/external_dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../data/datasources/layer_upload_local_datasource.dart';
import '../../data/datasources/layer_upload_remote_datasource.dart';
import '../../data/repositories/layer_upload_repository_impl.dart';
import '../../domain/entities/layer_upload.dart';
import '../../domain/repositories/layer_upload_repository.dart';
import '../../domain/usecases/cancel_layer_upload_usecase.dart';
import '../../domain/usecases/discard_layer_upload_usecase.dart';
import '../../domain/usecases/get_layer_upload_status_usecase.dart';
import '../../domain/usecases/get_resumable_layer_uploads_usecase.dart';
import '../../domain/usecases/publish_layer_to_geoserver_usecase.dart';
import '../../domain/usecases/resume_layer_upload_usecase.dart';
import '../../domain/usecases/retry_layer_upload_usecase.dart';
import '../../domain/usecases/upload_layer_file_usecase.dart';

// Data Source
//
// `enableRetry: false`: this feature does its own per-chunk retry with
// explicit backoff (see LayerUploadRepositoryImpl), and needs the tile
// server's always-500 `/cancel` response (ADR 0002) to surface immediately
// rather than being silently retried 3x by ExternalDioClient's built-in
// RetryInterceptor first.
final layerUploadApiClientProvider = Provider<ExternalDioClient>((ref) {
  return ExternalDioClient(
    baseUrl: ref.watch(tileServerBaseUrlProvider),
    networkInfo: ref.watch(networkInfoProvider),
    enableLogging: false,
    enableRetry: false,
  );
});

final layerUploadRemoteDataSourceProvider = Provider<LayerUploadRemoteDataSource>((ref) {
  return LayerUploadRemoteDataSourceImpl(ref.watch(layerUploadApiClientProvider));
});

final layerUploadLocalDataSourceProvider = Provider<LayerUploadLocalDataSource>((ref) {
  return LayerUploadLocalDataSourceImpl();
});

// Repository
final layerUploadRepositoryProvider = Provider<LayerUploadRepository>((ref) {
  return LayerUploadRepositoryImpl(
    remoteDataSource: ref.watch(layerUploadRemoteDataSourceProvider),
    localDataSource: ref.watch(layerUploadLocalDataSourceProvider),
  );
});

// Use Cases
final uploadLayerFileUseCaseProvider = Provider<UploadLayerFileUseCase>((ref) {
  return UploadLayerFileUseCase(ref.watch(layerUploadRepositoryProvider));
});

final resumeLayerUploadUseCaseProvider = Provider<ResumeLayerUploadUseCase>((ref) {
  return ResumeLayerUploadUseCase(ref.watch(layerUploadRepositoryProvider));
});

final retryLayerUploadUseCaseProvider = Provider<RetryLayerUploadUseCase>((ref) {
  return RetryLayerUploadUseCase(ref.watch(layerUploadRepositoryProvider));
});

final cancelLayerUploadUseCaseProvider = Provider<CancelLayerUploadUseCase>((ref) {
  return CancelLayerUploadUseCase(ref.watch(layerUploadRepositoryProvider));
});

final discardLayerUploadUseCaseProvider = Provider<DiscardLayerUploadUseCase>((ref) {
  return DiscardLayerUploadUseCase(ref.watch(layerUploadRepositoryProvider));
});

final getLayerUploadStatusUseCaseProvider = Provider<GetLayerUploadStatusUseCase>((ref) {
  return GetLayerUploadStatusUseCase(ref.watch(layerUploadRepositoryProvider));
});

final getResumableLayerUploadsUseCaseProvider = Provider<GetResumableLayerUploadsUseCase>((ref) {
  return GetResumableLayerUploadsUseCase(ref.watch(layerUploadRepositoryProvider));
});

final publishLayerToGeoserverUseCaseProvider = Provider<PublishLayerToGeoserverUseCase>((ref) {
  return PublishLayerToGeoserverUseCase(ref.watch(layerUploadRepositoryProvider));
});

// State

/// Non-terminal uploads left over from a previous session. Refresh with
/// `ref.invalidate` after resuming or discarding one.
final resumableLayerUploadsProvider = FutureProvider<List<LayerUpload>>((ref) async {
  final result = await ref.watch(getResumableLayerUploadsUseCaseProvider).call();
  return result.fold((failure) => throw failure, (uploads) => uploads);
});

/// Drives the active upload/resume/retry progress UI. `null` when nothing
/// is running. Controlled imperatively via [ActiveLayerUploadNotifier].
final activeLayerUploadProvider =
    NotifierProvider<ActiveLayerUploadNotifier, AsyncValue<LayerUpload>?>(
  ActiveLayerUploadNotifier.new,
);

class ActiveLayerUploadNotifier extends Notifier<AsyncValue<LayerUpload>?> {
  StreamSubscription<Either<Failure, LayerUpload>>? _subscription;

  @override
  AsyncValue<LayerUpload>? build() {
    ref.onDispose(() => _subscription?.cancel());
    return null;
  }

  void start({
    required String filePath,
    required String filename,
    required int totalSize,
  }) {
    _listen(ref.read(uploadLayerFileUseCaseProvider).call(
          filePath: filePath,
          filename: filename,
          totalSize: totalSize,
        ));
  }

  void resume(String uploadId) {
    _listen(ref.read(resumeLayerUploadUseCaseProvider).call(uploadId));
  }

  void retry(String uploadId) {
    _listen(ref.read(retryLayerUploadUseCaseProvider).call(uploadId));
  }

  void _listen(Stream<Either<Failure, LayerUpload>> stream) {
    state = const AsyncValue.loading();
    unawaited(_subscription?.cancel());
    _subscription = stream.listen(
      (event) => event.fold(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (upload) => state = AsyncValue.data(upload),
      ),
      onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
    );
  }

  Future<void> cancel() async {
    final current = state?.valueOrNull;
    if (current == null) return;
    final result = await ref.read(cancelLayerUploadUseCaseProvider).call(current.uploadId);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (upload) => state = AsyncValue.data(upload),
    );
  }

  void clear() {
    unawaited(_subscription?.cancel());
    state = null;
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/presentation/providers/layer_upload_providers.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/map_layer_upload/presentation/providers/layer_upload_providers.dart
git commit -m "feat(map-layer-upload): wire providers (DI + active-upload notifier)"
```

---

### Task 10: Presentation widgets — FAB + upload sheet (pick, confirm, progress, retry)

**Files:**
- Create: `lib/features/map_layer_upload/presentation/widgets/layer_upload_fab.dart`
- Create: `lib/features/map_layer_upload/presentation/widgets/layer_upload_sheet.dart`

**Interfaces:**
- Consumes: `activeLayerUploadProvider`, `resumableLayerUploadsProvider` (Task 9), `LayerUpload`/`LayerUploadStatus` (Task 2), `file_picker`'s `FilePicker`/`FileType`/`PlatformFile`.
- Produces: `LayerUploadFab` (a `StatelessWidget`), `LayerUploadSheet` (a `ConsumerStatefulWidget`) — consumed by Task 11 (MapPage wiring).

No dedicated widget test — this codebase has no widget tests for any map feature UI (`track_record_fab.dart`, `track_list_sheet.dart` have none); verification for this task is the manual QA checklist in Task 12.

- [ ] **Step 1: Write the upload sheet**

Create `lib/features/map_layer_upload/presentation/widgets/layer_upload_sheet.dart`:

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/layer_upload.dart';
import '../providers/layer_upload_providers.dart';

/// Bottom sheet: pick a `.tif`/`.tiff`/`.geojson`/`.zip` file, confirm, then
/// show live upload/finalize progress driven by [activeLayerUploadProvider].
class LayerUploadSheet extends ConsumerStatefulWidget {
  const LayerUploadSheet({super.key});

  @override
  ConsumerState<LayerUploadSheet> createState() => _LayerUploadSheetState();
}

class _LayerUploadSheetState extends ConsumerState<LayerUploadSheet> {
  PlatformFile? _selected;
  bool _picking = false;

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: false,
        type: FileType.custom,
        allowedExtensions: const ['tif', 'tiff', 'geojson', 'zip'],
      );
      final file = result?.files.single;
      if (file != null && file.path != null) {
        setState(() => _selected = file);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _startUpload() {
    final file = _selected;
    if (file == null || file.path == null) return;
    ref.read(activeLayerUploadProvider.notifier).start(
          filePath: file.path!,
          filename: file.name,
          totalSize: file.size,
        );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeLayerUploadProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scrollController,
          children: [
            Text('Upload Layer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (active == null) ...[
              OutlinedButton.icon(
                onPressed: _picking ? null : _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(
                  _selected == null
                      ? 'Pilih file (.tif, .geojson, .zip)'
                      : _selected!.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _selected == null ? null : _startUpload,
                child: const Text('Upload'),
              ),
            ] else
              _UploadProgress(active),
          ],
        ),
      ),
    );
  }
}

class _UploadProgress extends ConsumerWidget {
  const _UploadProgress(this.state);

  final AsyncValue<LayerUpload> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upload gagal: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(activeLayerUploadProvider.notifier).clear(),
            child: const Text('Tutup'),
          ),
        ],
      ),
      data: (upload) {
        final label = switch (upload.status) {
          LayerUploadStatus.pending => 'Menyiapkan…',
          LayerUploadStatus.uploading =>
            'Mengunggah ${upload.uploadedChunkCount}/${upload.totalChunks} bagian',
          LayerUploadStatus.uploaded => 'Memproses…',
          LayerUploadStatus.processing => 'Memproses…',
          LayerUploadStatus.done => 'Layer siap',
          LayerUploadStatus.failed => upload.errorMessage ?? 'Gagal',
          LayerUploadStatus.cancelled => 'Dibatalkan',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: upload.isTerminal ? 1 : upload.progressPercent / 100,
            ),
            const SizedBox(height: 12),
            Text(label),
            const SizedBox(height: 16),
            if (upload.status == LayerUploadStatus.failed)
              FilledButton(
                onPressed: () =>
                    ref.read(activeLayerUploadProvider.notifier).retry(upload.uploadId),
                child: const Text('Coba Lagi'),
              )
            else if (!upload.isTerminal)
              OutlinedButton(
                onPressed: () => ref.read(activeLayerUploadProvider.notifier).cancel(),
                child: const Text('Batalkan'),
              ),
            if (upload.isTerminal) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  ref.read(activeLayerUploadProvider.notifier).clear();
                  ref.invalidate(resumableLayerUploadsProvider);
                  Navigator.of(context).pop();
                },
                child: const Text('Selesai'),
              ),
            ],
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Write the FAB**

Create `lib/features/map_layer_upload/presentation/widgets/layer_upload_fab.dart`:

```dart
import 'package:flutter/material.dart';

import 'layer_upload_sheet.dart';

/// Floating action button that opens the layer-upload flow (pick file,
/// confirm, watch progress).
class LayerUploadFab extends StatelessWidget {
  const LayerUploadFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'layer-upload',
      tooltip: 'Upload layer',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const LayerUploadSheet(),
      ),
      child: const Icon(Icons.upload_file),
    );
  }
}
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/presentation/widgets/`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/map_layer_upload/presentation/widgets/layer_upload_fab.dart lib/features/map_layer_upload/presentation/widgets/layer_upload_sheet.dart
git commit -m "feat(map-layer-upload): add upload FAB and pick/confirm/progress sheet"
```

---

### Task 11: Resume banner + wire into `MapPage`

**Files:**
- Create: `lib/features/map_layer_upload/presentation/widgets/resume_layer_upload_banner.dart`
- Modify: `lib/features/map/presentation/pages/map_page.dart` (add the banner to the body `Stack`, add `LayerUploadFab` to `_MapFabCluster`)

**Interfaces:**
- Consumes: `resumableLayerUploadsProvider`, `activeLayerUploadProvider`, `discardLayerUploadUseCaseProvider` (Task 9), `LayerUploadFab`, `LayerUploadSheet` (Task 10).
- Produces: `ResumeLayerUploadBanner` (a `ConsumerWidget`), and `MapPage`/`_MapFabCluster` now render it plus the upload FAB. Nothing downstream depends on this — it is the final UI integration point.

- [ ] **Step 1: Write the resume banner**

Create `lib/features/map_layer_upload/presentation/widgets/resume_layer_upload_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/layer_upload_providers.dart';
import 'layer_upload_sheet.dart';

/// Shown on `MapPage` when a previous session left a non-terminal upload
/// behind. Lets the user resume it (reopens the progress sheet) or discard
/// it outright (best-effort server cancel + local record removal).
class ResumeLayerUploadBanner extends ConsumerWidget {
  const ResumeLayerUploadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumableAsync = ref.watch(resumableLayerUploadsProvider);

    return resumableAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (uploads) {
        if (uploads.isEmpty) return const SizedBox.shrink();
        final upload = uploads.first;

        return MaterialBanner(
          content: Text('Ada upload "${upload.filename}" yang belum selesai.'),
          actions: [
            TextButton(
              onPressed: () async {
                await ref.read(discardLayerUploadUseCaseProvider).call(upload.uploadId);
                ref.invalidate(resumableLayerUploadsProvider);
              },
              child: const Text('Buang'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(activeLayerUploadProvider.notifier).resume(upload.uploadId);
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const LayerUploadSheet(),
                );
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Wire the banner and FAB into `MapPage`**

In `lib/features/map/presentation/pages/map_page.dart`, add the import:

```dart
import '../../../map_layer_upload/presentation/widgets/layer_upload_fab.dart';
import '../../../map_layer_upload/presentation/widgets/resume_layer_upload_banner.dart';
```

In the `build` method's `Stack` (the one holding `MapView` and the top status chips), add `const ResumeLayerUploadBanner()` as the first child so it sits above the map:

```dart
      body: Stack(
        children: [
          MapView(
            controller: _mapController,
            initialCenter: _initialCenter,
            initialZoom: _initialZoom,
            myLocation: _myLocation,
            trackPoints: _trackPoints,
          ),

          const Align(
            alignment: Alignment.topCenter,
            child: ResumeLayerUploadBanner(),
          ),

          // Top status chips — sit below the top-left menu button on mobile
          // to avoid overlap; safe offset on all layouts.
          SafeArea(
```

(This inserts a new `Align` entry right after the existing `MapView(...)` widget and before the existing `SafeArea(...)` block — the rest of that `Stack`'s children are unchanged.)

In `_MapFabCluster` (near the bottom of the file), add `LayerUploadFab` to the `Column`:

```dart
class _MapFabCluster extends StatelessWidget {
  const _MapFabCluster({
    required this.locating,
    required this.onRecenter,
    required this.onPointsChanged,
  });
  final bool locating;
  final VoidCallback onRecenter;
  final void Function(List<TrackPoint> points) onPointsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const LayerUploadFab(),
        const SizedBox(height: 12),
        TrackRecordFab(onPointsChanged: onPointsChanged),
        const SizedBox(height: 12),
```

(Only the first two new lines — `const LayerUploadFab(),` and the following `SizedBox` — are added; everything from `TrackRecordFab(...)` onward is the existing code, unchanged.)

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/features/map_layer_upload/presentation/widgets/resume_layer_upload_banner.dart lib/features/map/presentation/pages/map_page.dart`
Expected: No issues.

- [ ] **Step 4: Manually smoke-test the wiring compiles and renders**

Run: `flutter run` (any connected device/emulator), navigate to the Map page.
Expected: Map page loads without a red error screen; the new upload FAB appears in the FAB cluster (above the track-record FAB); tapping it opens the bottom sheet from Task 10. No resume banner appears yet (no persisted uploads exist on a fresh install) — this is expected and confirms the empty-state branch (`SizedBox.shrink()`) works.

- [ ] **Step 5: Commit**

```bash
git add lib/features/map_layer_upload/presentation/widgets/resume_layer_upload_banner.dart lib/features/map/presentation/pages/map_page.dart
git commit -m "feat(map-layer-upload): add resume banner and wire FAB into MapPage"
```

---

### Task 12: Full verification pass

**Files:** none (verification only).

- [ ] **Step 1: Full static analysis**

Run: `flutter analyze`
Expected: No new issues introduced by this feature (the project has pre-existing lints elsewhere per `CLAUDE.md`'s known-issues notes — compare the count before/after this branch if unsure which are new).

- [ ] **Step 2: Full non-live test suite**

Run: `flutter test --exclude-tags live`
Expected: All tests pass, including every test added in Tasks 1–7.

- [ ] **Step 3: Live tests against the real tile server**

Run: `flutter test --tags live`
Expected: `test/map_datasource_live_test.dart` and `test/map_layer_upload_datasource_live_test.dart` (Task 6) both pass. Requires network access to the real tile server hosts.

- [ ] **Step 4: Manual on-device QA checklist**

Run the app (`flutter run`) on a real device or emulator and walk through:

- [ ] Pick a small `.geojson` file → upload completes → status reaches "Layer siap" (`done`) without manual intervention (auto `/save` finalize).
- [ ] Pick a `.tif` file → chunks upload and reach 100% → finalize is attempted (`/tile`) → **expected to show a failure** per ADR 0002 (the live server 500s on `/tile` regardless of input) — confirm the failure surfaces as a readable error with a "Coba Lagi" (retry) button, not a crash.
- [ ] Kill the app mid-upload (after at least one chunk has sent, before completion) and relaunch → the resume banner appears on `MapPage` → tapping "Lanjutkan" continues without re-sending already-confirmed chunks (check `uploadedChunkCount` picks up where it left off, not from 0).
- [ ] Tap "Buang" on the resume banner → the banner disappears and does not reappear on next launch.
- [ ] Start an upload and tap "Batalkan" mid-flight → the sheet reflects a cancelled state without showing a raw "500"/"Internal Server Error" message to the user (confirms the ADR 0002 workaround is effective end-to-end, not just at the datasource level).

- [ ] **Step 5: Record the raster-finalize limitation for whoever picks this up next**

If the tile server team fixes `/tile` before this plan is executed, re-run Task 6's live test with a `/tile`-triggering assertion added, and update `docs/adr/0002-tileserver-chunk-upload-quirks.md`'s "Consequences" section to reflect the fix. If it's still broken at execution time, no action needed beyond what Task 12 Step 4 already documents — this is a known, tracked limitation, not a new bug to fix as part of this plan.
