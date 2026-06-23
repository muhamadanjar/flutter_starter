import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDataSource.getProfile();
        await localDataSource.cacheProfile(profile);
        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return Left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
      } catch (_) {
        return _getCachedProfile();
      }
    } else {
      return _getCachedProfile();
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection. Cannot update profile.'));
    }

    try {
      final profile = await remoteDataSource.updateProfile(data);
      await localDataSource.cacheProfile(profile);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Server error'));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message ?? 'Validation error', fieldErrors: e.fieldErrors));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection. Cannot change password.'));
    }

    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Server error'));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message ?? 'Validation error', fieldErrors: e.fieldErrors));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message ?? 'Current password is incorrect'));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, UserProfile>> _getCachedProfile() async {
    try {
      final cached = await localDataSource.getCachedProfile();
      if (cached != null) return Right(cached);
      return const Left(CacheFailure(message: 'No cached profile data found'));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'Cache error'));
    }
  }
}
