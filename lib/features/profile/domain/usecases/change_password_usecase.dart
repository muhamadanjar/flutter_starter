import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class ChangePasswordUseCase {
  final ProfileRepository _repository;
  ChangePasswordUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
