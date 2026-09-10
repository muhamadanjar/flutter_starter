import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });

  Future<Map<String, dynamic>> loginWithSocialAuthorizationCode({
    required String authorizationCode,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  });

  Future<Map<String, dynamic>> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<void> logout();

  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dioClient);
  final DioClient _dioClient;

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final bodyData = {'username': username, 'password': password};

    final response = await _dioClient.post(
      ApiConstants.login,
      data: Uri(queryParameters: bodyData).query,
      options: Options(
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> loginWithSocialAuthorizationCode({
    required String authorizationCode,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  }) async {
    final tokenResponse = await _dioClient.post(
      ApiConstants.oauthToken,
      data: Uri(
        queryParameters: {
          'grant_type': 'authorization_code',
          'code': authorizationCode,
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'code_verifier': codeVerifier,
        },
      ).query,
      options: Options(
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );
    final oauthToken =
        (tokenResponse.data as Map<String, dynamic>)['access_token'] as String?;
    if (oauthToken == null || oauthToken.isEmpty) {
      throw const FormatException(
        'OAuth server did not return an access token.',
      );
    }

    final sessionResponse = await _dioClient.post(
      ApiConstants.oauthExchange,
      data: {'access_token': oauthToken},
    );
    return sessionResponse.data as Map<String, dynamic>;
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
  Future<void> logout() async {
    final response = await _dioClient.get(ApiConstants.logout);
    debugPrint(response.data);
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await _dioClient.get(ApiConstants.profile);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
