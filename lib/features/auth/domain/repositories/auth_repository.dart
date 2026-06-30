import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, User>> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User>> getProfile();

  Future<bool> isLoggedIn();

  Future<String?> getToken();
}
