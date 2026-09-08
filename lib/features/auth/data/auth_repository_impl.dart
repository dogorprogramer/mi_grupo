import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final AuthApi _api;
  final SecureStorageService _storage;

  @override
  Future<User> login({required String username, required String password}) async {
    final response = await _api.login(username: username, password: password);
    await _storage.write(AppConstants.authTokenKey, response.accessToken);
    return response.user.toDomain();
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _storage.read(AppConstants.authTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final user = await _api.getMe();
      return user.toDomain();
    } on AppException catch (e) {
      if (e.type == AppErrorType.unauthorized) {
        await _storage.delete(AppConstants.authTokenKey);
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(AppConstants.authTokenKey);
  }
}
