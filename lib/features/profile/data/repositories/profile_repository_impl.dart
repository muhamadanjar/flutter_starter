import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/dtos/index.dart';
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
        return right(profile);
      } on ServerException catch (e) {
        return left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
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
      return left(const NetworkFailure(message: 'No internet connection. Cannot update profile.'));
    }

    try {
      final profile = await remoteDataSource.updateProfile(data);
      await localDataSource.cacheProfile(profile);
      return right(profile);
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } on ValidationException catch (e) {
      return left(ValidationFailure(message: e.message ?? 'Validation error', fieldErrors: e.fieldErrors));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkFailure(message: 'No internet connection. Cannot change password.'));
    }

    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } on ValidationException catch (e) {
      return left(ValidationFailure(message: e.message ?? 'Validation error', fieldErrors: e.fieldErrors));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Current password is incorrect'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(File imageFile) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkFailure(message: 'No internet connection. Cannot upload avatar.'));
    }

    try {
      final imageUrl = await remoteDataSource.uploadAvatar(imageFile);
      return right(imageUrl);
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } on ValidationException catch (e) {
      return left(ValidationFailure(message: e.message ?? 'Validation error', fieldErrors: e.fieldErrors));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMetas() async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkFailure(message: 'No internet connection. Cannot load metadata.'));
    }

    try {
      final metas = await remoteDataSource.getMetas();
      return right(metas);
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> updateMetas(MetaUpdateRequest request) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkFailure(message: 'No internet connection. Cannot update metadata.'));
    }

    try {
      final result = await remoteDataSource.updateMetas(request);
      return right(result);
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } on ValidationException catch (e) {
      return left(ValidationFailure(message: e.message ?? 'Validation error', fieldErrors: e.fieldErrors));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, UserProfile>> _getCachedProfile() async {
    try {
      final cached = await localDataSource.getCachedProfile();
      if (cached != null) return right(cached);
      return left(const CacheFailure(message: 'No cached profile data found'));
    } on CacheException catch (e) {
      return left(CacheFailure(message: e.message ?? 'Cache error'));
    }
  }
}
