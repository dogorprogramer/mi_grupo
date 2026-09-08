import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/core/network/error_mapper.dart';

void main() {
  group('mapDioException', () {
    test('maps a connection timeout to AppErrorType.timeout', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = mapDioException(e);

      expect(result.type, AppErrorType.timeout);
    });

    test('maps a 401 response to AppErrorType.unauthorized', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 401,
        ),
      );

      final result = mapDioException(e);

      expect(result.type, AppErrorType.unauthorized);
    });

    test('maps a 400 response to AppErrorType.badRequest', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 400,
        ),
      );

      final result = mapDioException(e);

      expect(result.type, AppErrorType.badRequest);
      expect(result.message, isNot(contains('400')));
    });
  });
}
