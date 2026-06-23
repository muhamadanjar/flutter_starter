import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
