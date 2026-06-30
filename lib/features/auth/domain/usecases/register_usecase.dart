import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String username,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _repository.register(
      username: username,
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
