import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../providers/config_provider.dart';
import '../utils/mutex.dart';
import 'network_info.dart';
import 'retry_interceptor.dart';
import 'session_events.dart';

class DioClient {

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

    _refreshDio = Dio(
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
      RetryInterceptor(
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 500),
        backoffFactor: 2.0,
      ),
      _authInterceptor(),
      _logInterceptor(),
      _errorInterceptor(),
    ]);
  }
  late final Dio _dio;
  // Bare client for token refresh: no interceptors, so the refresh call never
  // carries an expired Bearer, never re-enters the 401 handler, and is not
  // retried by RetryInterceptor.
  late final Dio _refreshDio;
  final NetworkInfo _networkInfo;
  final Box<dynamic> _authBox;
  final AppConfig _config;
  final Mutex _tokenMutex = Mutex();

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
        final hasRefreshToken = _authBox.get(AppConstants.refreshTokenKey) != null;
        if (error.response?.statusCode == 401 && hasRefreshToken) {
          try {
            // Use mutex to prevent concurrent token refresh requests
            final failedAuth = error.requestOptions.headers['Authorization'];
            final newToken = await _tokenMutex.lock(() async {
              // Another request may have refreshed while we waited
              final current = _authBox.get(AppConstants.tokenKey) as String?;
              if (current != null && failedAuth != 'Bearer $current') {
                return current;
              }
              return _refreshToken();
            });
            if (newToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
            await _handleSessionExpired();
          } catch (_) {
            await _handleSessionExpired();
          }
        }
        handler.next(error);
      },
    );
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = _authBox.get(AppConstants.refreshTokenKey) as String?;
      if (refreshToken == null || refreshToken.isEmpty) return null;

      // /auth/refresh itself requires an Authorization header
      final currentToken = _authBox.get(AppConstants.tokenKey) as String?;
      final response = await _refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            if (currentToken != null) 'Authorization': 'Bearer $currentToken',
          },
        ),
      );

      // Response: {data: {auth: {access_token, ...}, user: {...}}}
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final auth = (data['auth'] ?? data) as Map<String, dynamic>;
      final newToken = auth['access_token'] as String?;
      final newRefreshToken = auth['refresh_token'] as String?;

      if (newToken != null) {
        await _authBox.put(AppConstants.tokenKey, newToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          // Server may not rotate the refresh token; keep the old one if absent
          await _authBox.put(AppConstants.refreshTokenKey, newRefreshToken);
        }
        return newToken;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSessionExpired() async {
    await _authBox.delete(AppConstants.tokenKey);
    await _authBox.delete(AppConstants.refreshTokenKey);
    SessionEvents.notifySessionExpired();
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
