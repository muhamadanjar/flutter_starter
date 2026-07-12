import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import 'dio_error_mapper.dart';
import 'network_info.dart';
import 'retry_interceptor.dart';

/// Dio client for third-party APIs, independent of the internal API client.
///
/// Unlike `DioClient` it carries no app auth: no Bearer token, no token
/// refresh, no `AppConfig` coupling. Errors map to the same app exceptions
/// so callers handle failures uniformly.
///
/// Each external API declares its own provider in its feature:
///
/// ```dart
/// final weatherApiClientProvider = Provider<ExternalDioClient>((ref) {
///   return ExternalDioClient(
///     baseUrl: 'https://api.weather.example.com/v1',
///     networkInfo: ref.watch(networkInfoProvider),
///     defaultHeaders: {'X-Api-Key': 'xxx'},
///   );
/// });
/// ```
class ExternalDioClient {

  ExternalDioClient({
    required String baseUrl,
    required NetworkInfo networkInfo,
    Map<String, String>? defaultHeaders,
    Duration timeout = const Duration(seconds: 30),
    bool enableRetry = true,
    bool enableLogging = true,
  }) : _networkInfo = networkInfo {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?defaultHeaders,
        },
      ),
    );

    _dio.interceptors.addAll([
      if (enableRetry)
        RetryInterceptor(
          maxRetries: 3,
          initialDelay: const Duration(milliseconds: 500),
          backoffFactor: 2.0,
        ),
      if (enableLogging)
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      DioErrorMapper.errorInterceptor(),
    ]);
  }

  late final Dio _dio;
  final NetworkInfo _networkInfo;

  // GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureConnected();
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw DioErrorMapper.map(e);
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
    await _ensureConnected();
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw DioErrorMapper.map(e);
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
    await _ensureConnected();
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw DioErrorMapper.map(e);
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
    await _ensureConnected();
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  Future<void> _ensureConnected() async {
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) {
      throw const NetworkException(message: 'No internet connection.');
    }
  }
}
