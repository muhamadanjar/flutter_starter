import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Retry interceptor with exponential backoff
class RetryInterceptor extends Interceptor {

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffFactor = 2.0,
  });
  final int maxRetries;
  final Duration initialDelay;
  final double backoffFactor;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && err.requestOptions.extra['retries'] == null) {
      int retryCount = 0;

      while (retryCount < maxRetries) {
        try {
          // Calculate backoff delay
          final delayMs = (initialDelay.inMilliseconds * math.pow(backoffFactor, retryCount)).toInt();
          await Future.delayed(Duration(milliseconds: delayMs));

          retryCount++;

          // Retry request
          final response = await Dio().fetch<dynamic>(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          if (retryCount >= maxRetries || !_shouldRetry(e)) {
            return handler.next(e);
          }
        } catch (e) {
          return handler.next(err);
        }
      }
    }

    handler.next(err);
  }

  /// Determine if error is retryable
  bool _shouldRetry(DioException err) {
    // Don't retry cancelled requests
    if (err.type == DioExceptionType.cancel) return false;

    // Retry on timeout
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // Retry on connection errors
    if (err.type == DioExceptionType.connectionError) return true;

    // Retry on server errors (5xx)
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode != null && statusCode >= 500) return true;

      // Retry on rate limit (429)
      if (statusCode == 429) return true;

      // Don't retry client errors (4xx except 429)
      if (statusCode != null && statusCode >= 400) return false;
    }

    return false;
  }
}
