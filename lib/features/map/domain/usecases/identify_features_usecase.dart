import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/map_repository.dart';

class IdentifyFeaturesUseCase {
  IdentifyFeaturesUseCase(this._repository);

  final MapRepository _repository;

  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required String layerId,
    required double lon,
    required double lat,
  }) {
    return _repository.identify(layerId: layerId, lon: lon, lat: lat);
  }
}
