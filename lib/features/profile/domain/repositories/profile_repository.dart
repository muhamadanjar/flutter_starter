import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../dtos/index.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile();
  Future<Either<Failure, UserProfile>> updateProfile(Map<String, dynamic> data);
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Either<Failure, String>> uploadAvatar(File imageFile);
  Future<Either<Failure, Map<String, dynamic>>> getMetas();
  Future<Either<Failure, dynamic>> updateMetas(MetaUpdateRequest request);
}
