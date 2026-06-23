class ServerException implements Exception {
  final String? message;
  final int? statusCode;
  final String? errorCode;

  const ServerException({
    this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message, errorCode: $errorCode)';
}

class CacheException implements Exception {
  final String? message;

  const CacheException({this.message});

  @override
  String toString() => 'CacheException(message: $message)';
}

class NetworkException implements Exception {
  final String? message;

  const NetworkException({this.message});

  @override
  String toString() => 'NetworkException(message: $message)';
}

class UnauthorizedException implements Exception {
  final String? message;

  const UnauthorizedException({this.message});

  @override
  String toString() => 'UnauthorizedException(message: $message)';
}

class ValidationException implements Exception {
  final String? message;
  final Map<String, String>? fieldErrors;

  const ValidationException({this.message, this.fieldErrors});

  @override
  String toString() => 'ValidationException(message: $message, fieldErrors: $fieldErrors)';
}

class TimeoutException implements Exception {
  final String? message;

  const TimeoutException({this.message});

  @override
  String toString() => 'TimeoutException(message: $message)';
}
