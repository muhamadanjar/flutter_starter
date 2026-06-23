import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  ProfileRemoteDataSourceImpl(this._dioClient);

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await _dioClient.get(ApiConstants.profile);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserProfileModel.fromJson(data);
  }

  @override
  Future<UserProfileModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dioClient.put(ApiConstants.updateProfile, data: data);
    final responseData = response.data['data'] as Map<String, dynamic>;
    return UserProfileModel.fromJson(responseData);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dioClient.post(ApiConstants.changePassword, data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': confirmPassword,
    });
  }
}
