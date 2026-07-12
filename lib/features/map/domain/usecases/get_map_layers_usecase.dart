import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/map_layer.dart';
import '../repositories/map_repository.dart';

class GetMapLayersUseCase {
  GetMapLayersUseCase(this._repository);

  final MapRepository _repository;

  Future<Either<Failure, List<MapLayer>>> call() => _repository.getLayers();
}
