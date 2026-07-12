import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/external_dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/preferences/pref_providers.dart';
import '../../data/datasources/map_remote_datasource.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/basemap.dart';
import '../../domain/entities/map_layer.dart';
import '../../domain/usecases/get_map_layers_usecase.dart';
import '../../domain/usecases/identify_features_usecase.dart';

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
