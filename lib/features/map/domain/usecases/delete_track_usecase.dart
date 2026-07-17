import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/track_record_repository.dart';

/// Remove a track from local storage.
class DeleteTrackUseCase {
  const DeleteTrackUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, Unit>> call(String trackId) =>
      _repository.deleteTrack(trackId);
}
