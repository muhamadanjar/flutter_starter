class ServerException implements Exception {

  const ServerException({
    this.message,
    this.statusCode,
    this.errorCode,
  });
  final String? message;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message, errorCode: $errorCode)';
}

class CacheException implements Exception {

  const CacheException({this.message});
  final String? message;

  @override
  String toString() => 'CacheException(message: $message)';
}

class NetworkException implements Exception {

  const NetworkException({this.message});
  final String? message;

  @override
  String toString() => 'NetworkException(message: $message)';
}

class UnauthorizedException implements Exception {

  const UnauthorizedException({this.message});
  final String? message;

  @override
  String toString() => 'UnauthorizedException(message: $message)';
}

class ValidationException implements Exception {

  const ValidationException({this.message, this.fieldErrors});
  final String? message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => 'ValidationException(message: $message, fieldErrors: $fieldErrors)';
}

class TimeoutException implements Exception {

  const TimeoutException({this.message});
  final String? message;

  @override
  String toString() => 'TimeoutException(message: $message)';
}
