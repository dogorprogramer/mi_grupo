import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureStorageService _storage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _addAuthorizationHeader(options).then((_) => handler.next(options));
  }

  Future<void> _addAuthorizationHeader(RequestOptions options) async {
    try {
      final token = await _storage.read(AppConstants.authTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Token not available; proceed without the header.
    }
  }
}
