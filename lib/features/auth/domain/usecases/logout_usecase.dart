import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {

  LogoutUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
