import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/external_dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/preferences/pref_providers.dart';
import '../../data/datasources/map_remote_datasource.dart';
import '../../data/datasources/track_record_local_datasource.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../data/repositories/track_record_repository_impl.dart';
import '../../domain/entities/basemap.dart';
import '../../domain/entities/map_layer.dart';
import '../../domain/entities/track_record.dart';
import '../../domain/repositories/track_record_repository.dart';
import '../../domain/usecases/add_track_point_usecase.dart';
import '../../domain/usecases/delete_track_usecase.dart';
import '../../domain/usecases/get_map_layers_usecase.dart';
import '../../domain/usecases/get_pending_tracks_usecase.dart';
import '../../domain/usecases/get_track_records_usecase.dart';
import '../../domain/usecases/identify_features_usecase.dart';
import '../../domain/usecases/start_track_usecase.dart';
import '../../domain/usecases/sync_track_records_usecase.dart';

/// Tile server base URL from `.env` (`TILE_SERVER_URL`), with a LAN
/// default when the entry or the file is missing.
final tileServerBaseUrlProvider = Provider<String>((ref) {
  return dotenv.maybeGet('TILE_SERVER_URL') ?? 'http://192.168.1.3:8050';
});

// Data Source
final mapApiClientProvider = Provider<ExternalDioClient>((ref) {
  return ExternalDioClient(
    baseUrl: ref.watch(tileServerBaseUrlProvider),
    networkInfo: ref.watch(networkInfoProvider),
    enableLogging: false,
  );
});

final mapRemoteDataSourceProvider = Provider<MapRemoteDataSource>((ref) {
  return MapRemoteDataSourceImpl(ref.watch(mapApiClientProvider));
});

// Repository
final mapRepositoryProvider = Provider<MapRepositoryImpl>((ref) {
  return MapRepositoryImpl(
    remoteDataSource: ref.watch(mapRemoteDataSourceProvider),
  );
});

// Use Cases
final getMapLayersUseCaseProvider = Provider<GetMapLayersUseCase>((ref) {
  return GetMapLayersUseCase(ref.watch(mapRepositoryProvider));
});

final identifyFeaturesUseCaseProvider = Provider<IdentifyFeaturesUseCase>((ref) {
  return IdentifyFeaturesUseCase(ref.watch(mapRepositoryProvider));
});

// State

/// Layer catalog from the tile server. Refresh with `ref.invalidate`.
final mapCatalogProvider = FutureProvider<List<MapLayer>>((ref) async {
  final result = await ref.watch(getMapLayersUseCaseProvider).call();
  return result.fold((failure) => throw failure, (layers) => layers);
});

/// IDs of overlay layers currently shown on the map. Session-only.
final visibleLayerIdsProvider =
    StateProvider<Set<String>>((ref) => const <String>{});

/// Selected basemap, persisted in `UserPref.basemap`.
final basemapProvider = NotifierProvider<BasemapNotifier, Basemap>(
  BasemapNotifier.new,
);

class BasemapNotifier extends Notifier<Basemap> {
  @override
  Basemap build() {
    final pref = ref.read(userPrefProvider);
    return Basemap.fromName(pref.basemap.get());
  }

  Future<void> select(Basemap basemap) async {
    state = basemap;
    await ref.read(userPrefProvider).basemap.put(basemap.name);
  }
}

// ---------------------------------------------------------------------------
// Track Record (offline GPS tracking + sync outbox)
// ---------------------------------------------------------------------------

final trackRecordLocalDataSourceProvider =
    Provider<TrackRecordLocalDataSource>((ref) {
  return TrackRecordLocalDataSourceImpl();
});

final trackRecordRepositoryProvider =
    Provider<TrackRecordRepository>((ref) {
  return TrackRecordRepositoryImpl(
    localDataSource: ref.watch(trackRecordLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

final startTrackUseCaseProvider = Provider<StartTrackUseCase>((ref) {
  return StartTrackUseCase(ref.watch(trackRecordRepositoryProvider));
});

final addTrackPointUseCaseProvider = Provider<AddTrackPointUseCase>((ref) {
  return AddTrackPointUseCase(ref.watch(trackRecordRepositoryProvider));
});

final getTrackRecordsUseCaseProvider = Provider<GetTrackRecordsUseCase>((ref) {
  return GetTrackRecordsUseCase(ref.watch(trackRecordRepositoryProvider));
});

final syncTrackRecordsUseCaseProvider = Provider<SyncTrackRecordsUseCase>((ref) {
  return SyncTrackRecordsUseCase(ref.watch(trackRecordRepositoryProvider));
});

/// All stored tracks (newest first). Refresh with `ref.invalidate`.
final trackRecordsProvider = FutureProvider<List<TrackRecord>>((ref) async {
  final result = await ref.watch(getTrackRecordsUseCaseProvider).call();
  return result.fold((failure) => throw failure, (tracks) => tracks);
});

/// Id of the track currently being recorded, or null when idle.
final activeTrackIdProvider = StateProvider<String?>((ref) => null);

/// One-shot sync trigger: call `ref.refresh` or watch to flush the outbox.
final trackSyncProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(syncTrackRecordsUseCaseProvider).call();
  return result.fold((failure) => throw failure, (count) => count);
});

final deleteTrackUseCaseProvider = Provider<DeleteTrackUseCase>((ref) {
  return DeleteTrackUseCase(ref.watch(trackRecordRepositoryProvider));
});

final getPendingTracksUseCaseProvider = Provider<GetPendingTracksUseCase>((ref) {
  return GetPendingTracksUseCase(ref.watch(trackRecordRepositoryProvider));
});

/// Tracks waiting to be pushed to the server. Refresh with `ref.invalidate`.
final pendingTracksProvider = FutureProvider<List<TrackRecord>>((ref) async {
  final result = await ref.watch(getPendingTracksUseCaseProvider).call();
  return result.fold((failure) => throw failure, (tracks) => tracks);
});
