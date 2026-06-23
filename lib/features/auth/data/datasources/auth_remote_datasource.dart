import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<void> logout();

  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    await _dioClient.post(ApiConstants.logout);
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await _dioClient.get(ApiConstants.profile);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
