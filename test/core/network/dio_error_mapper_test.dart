import 'package:dio/dio.dart';
import 'package:enterprise_flutter_app/core/errors/exceptions.dart';
import 'package:enterprise_flutter_app/core/network/dio_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int statusCode, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  group('DioErrorMapper.map 422 handling', () {
    test('parses FastAPI-style {"detail":[...]} into fieldErrors', () {
      final err = _badResponse(422, {
        'detail': [
          {
            'type': 'missing',
            'loc': ['body', 'filename'],
            'msg': 'Field required',
          },
          {
            'type': 'greater_than',
            'loc': ['body', 'total_size'],
            'msg': 'Input should be greater than 0',
          },
        ],
      });

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ValidationException>());
      final validation = mapped as ValidationException;
      expect(validation.fieldErrors, {
        'filename': 'Field required',
        'total_size': 'Input should be greater than 0',
      });
    });

    test('still parses the internal-API {"errors": {...}} shape (regression)', () {
      final err = _badResponse(422, {
        'message': 'Validation failed',
        'errors': {'email': 'Email is invalid'},
      });

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ValidationException>());
      final validation = mapped as ValidationException;
      expect(validation.fieldErrors, {'email': 'Email is invalid'});
      expect(validation.message, 'Validation failed');
    });

    test('handles a 422 with neither shape without throwing', () {
      final err = _badResponse(422, {'unexpected': true});

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ValidationException>());
      expect((mapped as ValidationException).fieldErrors, isEmpty);
    });
  });

  group('DioErrorMapper.map error body type handling', () {
    test('maps a plain-text (String) error body without throwing', () {
      final err = _badResponse(500, 'Internal Server Error');

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ServerException>());
      final serverEx = mapped as ServerException;
      expect(serverEx.message, 'Internal Server Error');
      expect(serverEx.statusCode, 500);
    });

    test('maps a non-JSON response body (e.g., tile server /cancel quirk)', () {
      final err = _badResponse(500, 'text/plain response body');

      final mapped = DioErrorMapper.map(err);

      expect(mapped, isA<ServerException>());
      final serverEx = mapped as ServerException;
      expect(serverEx.statusCode, 500);
      expect(serverEx.message, 'text/plain response body');
    });
  });
}
