import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {

    final bodyData = {
      'username': username,
      'password': password,
    };

    final response = await _dioClient.post(
      ApiConstants.login,
      data: Uri(queryParameters: bodyData).query,
      options: Options(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.register,
      data: {
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await _dioClient.get(ApiConstants.profile);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
