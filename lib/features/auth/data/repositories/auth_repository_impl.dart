import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkFailure(message: 'No internet connection. Please check your network.'));
    }

    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );

      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String? ?? '';
      final refreshToken = data['refresh_token'] as String? ?? '';
      final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Save to local storage
      await localDataSource.saveToken(token);
      await localDataSource.saveRefreshToken(refreshToken);
      await localDataSource.saveUserId(userModel.id);
      await localDataSource.saveUser(userModel);
      await localDataSource.setLoggedIn(true);

      return right(userModel);
    } on ServerException catch (e) {
      return left(ServerFailure(
        message: e.message ?? 'Server error occurred',
        statusCode: e.statusCode,
      ));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
    } on ValidationException catch (e) {
      return left(ValidationFailure(
        message: e.message ?? 'Validation error',
        fieldErrors: e.fieldErrors,
      ));
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'Network error'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkFailure(message: 'No internet connection. Please check your network.'));
    }

    try {
      final response = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String? ?? '';
      final refreshToken = data['refresh_token'] as String? ?? '';
      final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await localDataSource.saveToken(token);
      await localDataSource.saveRefreshToken(refreshToken);
      await localDataSource.saveUserId(userModel.id);
      await localDataSource.saveUser(userModel);
      await localDataSource.setLoggedIn(true);

      return right(userModel);
    } on ServerException catch (e) {
      return left(ServerFailure(
        message: e.message ?? 'Server error occurred',
        statusCode: e.statusCode,
      ));
    } on ValidationException catch (e) {
      return left(ValidationFailure(
        message: e.message ?? 'Validation error',
        fieldErrors: e.fieldErrors,
      ));
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'Network error'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }
      await localDataSource.clearAll();
      return right(null);
    } on ServerException catch (e) {
      // Even if server logout fails, clear local data
      await localDataSource.clearAll();
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      await localDataSource.clearAll();
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.getProfile();
        await localDataSource.saveUser(userModel);
        return right(userModel);
      } on ServerException catch (e) {
        return left(ServerFailure(
          message: e.message ?? 'Server error occurred',
          statusCode: e.statusCode,
        ));
      } on UnauthorizedException catch (e) {
        return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
      } catch (e) {
        // Fallback to cache on error
        return _getCachedUser();
      }
    } else {
      return _getCachedUser();
    }
  }

  Future<Either<Failure, User>> _getCachedUser() async {
    try {
      final cachedUser = await localDataSource.getUser();
      if (cachedUser != null) {
        return right(cachedUser);
      }
      return left(CacheFailure(message: 'No cached user data found'));
    } on CacheException catch (e) {
      return left(CacheFailure(message: e.message ?? 'Cache error'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return localDataSource.isLoggedIn();
  }

  @override
  Future<String?> getToken() async {
    return localDataSource.getToken();
  }
}
