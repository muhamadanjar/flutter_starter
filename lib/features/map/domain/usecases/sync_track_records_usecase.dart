import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/track_record_repository.dart';

class SyncTrackRecordsUseCase {
  SyncTrackRecordsUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, int>> call() => _repository.syncPending();
}
