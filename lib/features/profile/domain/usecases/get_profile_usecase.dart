import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository _repository;
  GetProfileUseCase(this._repository);

  Future<Either<Failure, UserProfile>> call() => _repository.getProfile();
}
