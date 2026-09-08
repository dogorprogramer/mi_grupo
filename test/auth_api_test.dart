import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/features/auth/data/auth_api.dart';

class Fake400Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"Invalid credentials"}',
      400,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('login with HTTP 400 maps to a friendly credentials message', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));
    dio.httpClientAdapter = Fake400Adapter();
    final api = AuthApi(dio);

    await expectLater(
      api.login(username: 'emilys', password: 'wrong'),
      throwsA(
        isA<AppException>()
            .having((e) => e.type, 'type', AppErrorType.badRequest)
            .having((e) => e.message, 'message', 'Usuario o contraseña incorrectos.'),
      ),
    );
  });
}
