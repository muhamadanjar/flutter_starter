import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SocialLoginUseCase {
  const SocialLoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, User>> call({
    required String authorizationCode,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  }) =>
      _repository.loginWithSocialAuthorizationCode(
        authorizationCode: authorizationCode,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
        clientId: clientId,
      );
}
