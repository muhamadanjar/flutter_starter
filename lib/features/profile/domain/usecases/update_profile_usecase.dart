import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;
  UpdateProfileUseCase(this._repository);

  Future<Either<Failure, UserProfile>> call(Map<String, dynamic> data) => _repository.updateProfile(data);
}
