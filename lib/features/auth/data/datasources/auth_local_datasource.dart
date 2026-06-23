import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<void> saveRefreshToken(String refreshToken);
  Future<void> saveUserId(String userId);
  Future<void> saveUser(UserModel user);
  Future<void> setLoggedIn(bool isLoggedIn);
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<String?> getUserId();
  Future<UserModel?> getUser();
  Future<bool> isLoggedIn();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box<dynamic> _authBox;
  final Box<dynamic> _userBox;

  AuthLocalDataSourceImpl({
    required Box<dynamic> authBox,
    required Box<dynamic> userBox,
  })  : _authBox = authBox,
        _userBox = userBox;

  @override
  Future<void> saveToken(String token) async {
    await _authBox.put(AppConstants.tokenKey, token);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await _authBox.put(AppConstants.refreshTokenKey, refreshToken);
  }

  @override
  Future<void> saveUserId(String userId) async {
    await _authBox.put(AppConstants.userIdKey, userId);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _userBox.put(AppConstants.userProfileKey, user.toLocalJson());
  }

  @override
  Future<void> setLoggedIn(bool isLoggedIn) async {
    await _authBox.put(AppConstants.isLoggedInKey, isLoggedIn);
  }

  @override
  Future<String?> getToken() async {
    return _authBox.get(AppConstants.tokenKey) as String?;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _authBox.get(AppConstants.refreshTokenKey) as String?;
  }

  @override
  Future<String?> getUserId() async {
    return _authBox.get(AppConstants.userIdKey) as String?;
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userJson = _userBox.get(AppConstants.userProfileKey) as Map?;
      if (userJson == null) return null;
      return UserModel.fromLocalJson(Map<String, dynamic>.from(userJson));
    } catch (_) {
      throw const CacheException(message: 'Failed to read user from cache');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return _authBox.get(AppConstants.isLoggedInKey) as bool? ?? false;
  }

  @override
  Future<void> clearAll() async {
    await _authBox.clear();
    await _userBox.clear();
  }
}
