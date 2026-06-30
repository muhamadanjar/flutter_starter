import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../providers/config_provider.dart';
import 'network_info.dart';

class DioClient {
  late final Dio _dio;
  final NetworkInfo _networkInfo;
  final Box<dynamic> _authBox;
  final AppConfig _config;

  DioClient({
    required NetworkInfo networkInfo,
    required Box<dynamic> authBox,
    required AppConfig config,
  })  : _networkInfo = networkInfo,
        _authBox = authBox,
        _config = config {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.requestTimeout,
        receiveTimeout: _config.requestTimeout,
        sendTimeout: _config.requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Version': _config.apiVersion,
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _logInterceptor(),
      _errorInterceptor(),
    ]);
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _authBox.get(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final newToken = await _refreshToken();
            if (newToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (_) {
            // Refresh failed, proceed with original error
          }
        }
        handler.next(error);
      },
    );
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = _authBox.get(AppConstants.refreshTokenKey);
      if (refreshToken == null) return null;

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newToken = response.data['data']['token'] as String?;
      final newRefreshToken = response.data['data']['refresh_token'] as String?;

      if (newToken != null) {
        await _authBox.put(AppConstants.tokenKey, newToken);
        if (newRefreshToken != null) {
          await _authBox.put(AppConstants.refreshTokenKey, newRefreshToken);
        }
        return newToken;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  LogInterceptor _logInterceptor() {
    return LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    );
  }

  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            handler.next(
              DioException(
                requestOptions: error.requestOptions,
                error: const TimeoutException(message: 'Connection timeout. Please try again.'),
                type: error.type,
              ),
            );
            break;
          case DioExceptionType.connectionError:
            handler.next(
              DioException(
                requestOptions: error.requestOptions,
                error: const NetworkException(message: 'No internet connection. Please check your network.'),
                type: error.type,
              ),
            );
            break;
          default:
            handler.next(error);
        }
      },
    );
  }

  // GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      throw const NetworkException(message: 'No internet connection.');
    }

    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      throw const NetworkException(message: 'No internet connection.');
    }

    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      throw const NetworkException(message: 'No internet connection.');
    }

    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      throw const NetworkException(message: 'No internet connection.');
    }

    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(message: 'Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] as String? ?? 'Something went wrong.';
        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        }
        if (statusCode == 422) {
          final fieldErrors = <String, String>{};
          final errors = error.response?.data?['errors'];
          if (errors is Map) {
            errors.forEach((key, value) {
              fieldErrors[key.toString()] = value.toString();
            });
          }
          return ValidationException(message: message, fieldErrors: fieldErrors);
        }
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return const ServerException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection.');
      default:
        return const ServerException(message: 'Unexpected error occurred.');
    }
  }
}

final dioClientProvider = Provider<DioClient>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  final authBox = Hive.box(AppConstants.authBox);
  final config = ref.watch(appConfigProvider);
  return DioClient(
    networkInfo: networkInfo,
    authBox: authBox,
    config: config,
  );
});
