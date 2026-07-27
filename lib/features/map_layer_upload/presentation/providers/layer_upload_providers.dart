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
    // Stop the still-running upload/resume/retry pipeline stream first, so
    // it can no longer emit stale progress over the cancelled state or fire
    // further chunk POSTs against a server-side-cancelled upload.
    await _subscription?.cancel();
    _subscription = null;
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
