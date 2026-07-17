import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/track_record_repository.dart';

class StartTrackUseCase {
  StartTrackUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, String>> call({required String name, String note = ''}) =>
      _repository.startTrack(name: name, note: note);
}
