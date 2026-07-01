import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/meta_update_request.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Map<String, dynamic>> getMetas();

  /// Upsert metadata (single or bulk)
  ///
  /// Single: updateMetas(SingleMetaUpdate(key: 'theme', value: 'dark'))
  /// Bulk:   updateMetas(BulkMetaUpdate(items: [MetaItem(key: 'theme', value: 'dark'), ...]))
  Future<dynamic> updateMetas(MetaUpdateRequest request);
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
    final response = await _dioClient.post(ApiConstants.changePassword, data: {
      'old_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });

  }

  @override
  Future<Map<String, dynamic>> getMetas() async {
    final response = await _dioClient.get(ApiConstants.authMetas);
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<dynamic> updateMetas(MetaUpdateRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.authMetas,
      data: request.toJson(),
    );

    final responseData = response.data['data'];

    // Single: return Map
    if (responseData is Map) {
      return responseData as Map<String, dynamic>;
    }

    // Bulk: return List
    if (responseData is List) {
      return responseData.cast<Map<String, dynamic>>();
    }

    return responseData;
  }
}
