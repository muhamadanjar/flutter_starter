import '../../../../core/network/external_dio_client.dart';
import '../models/map_layer_model.dart';

abstract class MapRemoteDataSource {
  Future<List<MapLayerModel>> getLayers();

  Future<List<Map<String, dynamic>>> identify({
    required String layerId,
    required double lon,
    required double lat,
  });
}

/// Talks to the FastAPI tile server (layer catalog + feature queries).
class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  MapRemoteDataSourceImpl(this._client);

  final ExternalDioClient _client;

  @override
  Future<List<MapLayerModel>> getLayers() async {
    final response = await _client.get<Map<String, dynamic>>('/api/v1/layers');
    final data = response.data?['data'] as List? ?? const [];
    return [
      for (final item in data)
        if (item is Map<String, dynamic>) MapLayerModel.fromJson(item),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> identify({
    required String layerId,
    required double lon,
    required double lat,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/layers/$layerId/features',
      queryParameters: {'lon': lon, 'lat': lat},
    );
    final features = response.data?['features'] as List? ?? const [];
    return [
      for (final f in features)
        if (f is Map<String, dynamic>) f,
    ];
  }
}
