import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/track_record.dart';
import '../../domain/repositories/track_record_repository.dart';

/// Tracks not yet delivered to the server (outbox).
class GetPendingTracksUseCase {
  const GetPendingTracksUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, List<TrackRecord>>> call() =>
      _repository.getPending();
}
