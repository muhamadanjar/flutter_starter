import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/map_layer.dart';

abstract class MapRepository {
  /// Full layer catalog from the tile server.
  Future<Either<Failure, List<MapLayer>>> getLayers();

  /// Identify features of one layer at a point. Returns flat attribute
  /// maps (works for all layer types; server proxies esri identify).
  Future<Either<Failure, List<Map<String, dynamic>>>> identify({
    required String layerId,
    required double lon,
    required double lat,
  });
}
