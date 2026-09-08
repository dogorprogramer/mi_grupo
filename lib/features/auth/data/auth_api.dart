import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/error_mapper.dart';
import 'models/auth_response.dart';
import 'models/user_dto.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthResponse> login({required String username, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapLoginError(e);
    }
  }

  Future<UserDto> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return UserDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  AppException _mapLoginError(DioException e) {
    if (e.type == DioExceptionType.badResponse && e.response?.statusCode == 400) {
      return const AppException(
        AppErrorType.badRequest,
        'Usuario o contraseña incorrectos.',
      );
    }
    return mapDioException(e);
  }
}
