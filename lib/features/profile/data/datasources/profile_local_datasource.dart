import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<void> cacheProfile(UserProfileModel profile);
  Future<UserProfileModel?> getCachedProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final Box<dynamic> _userBox;

  ProfileLocalDataSourceImpl({required Box<dynamic> userBox}) : _userBox = userBox;

  @override
  Future<void> cacheProfile(UserProfileModel profile) async {
    await _userBox.put(AppConstants.userProfileKey, profile.toLocalJson());
  }

  @override
  Future<UserProfileModel?> getCachedProfile() async {
    try {
      final json = _userBox.get(AppConstants.userProfileKey) as Map?;
      if (json == null) return null;
      return UserProfileModel.fromLocalJson(Map<String, dynamic>.from(json));
    } catch (_) {
      throw const CacheException(message: 'Failed to read profile from cache');
    }
  }
}
