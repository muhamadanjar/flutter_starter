import 'package:dio/dio.dart';

import '../errors/exceptions.dart';

/// Shared Dio error handling used by both `DioClient` (internal API) and
/// `ExternalDioClient` (third-party APIs) so error semantics stay identical.
class DioErrorMapper {
  const DioErrorMapper._();

  /// Interceptor that rewraps timeout/connection errors with app exceptions.
  static InterceptorsWrapper errorInterceptor() {
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

  /// Maps a [DioException] to the corresponding app exception.
  static Exception map(DioException error) {
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
