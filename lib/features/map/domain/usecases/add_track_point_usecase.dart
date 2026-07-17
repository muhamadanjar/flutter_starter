import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/track_record_repository.dart';

class AddTrackPointUseCase {
  AddTrackPointUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, Unit>> call(
    String trackId, {
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    double speed = 0.0,
    double accuracy = 0.0,
    DateTime? timestamp,
  }) =>
      _repository.addPoint(
        trackId,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        speed: speed,
        accuracy: accuracy,
        timestamp: timestamp,
      );
}
