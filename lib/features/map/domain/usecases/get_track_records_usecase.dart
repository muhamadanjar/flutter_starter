import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track_record.dart';
import '../repositories/track_record_repository.dart';

class GetTrackRecordsUseCase {
  GetTrackRecordsUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, List<TrackRecord>>> call() => _repository.getTracks();
}
