import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/map_layer.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl({required this.remoteDataSource});

  final MapRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<MapLayer>>> getLayers() async {
    try {
      final layers = await remoteDataSource.getLayers();
      return right(layers);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> identify({
    required String layerId,
    required double lon,
    required double lat,
  }) async {
    try {
      final features = await remoteDataSource.identify(
        layerId: layerId,
        lon: lon,
        lat: lat,
      );
      return right(features);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
