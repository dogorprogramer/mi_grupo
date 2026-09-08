import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/constants/app_constants.dart';
import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/core/storage/secure_storage_service.dart';
import 'package:mi_grupo/features/auth/data/auth_api.dart';
import 'package:mi_grupo/features/auth/data/auth_repository_impl.dart';
import 'package:mi_grupo/features/auth/data/models/auth_response.dart';
import 'package:mi_grupo/features/auth/data/models/user_dto.dart';

class FakeAuthApi extends AuthApi {
  FakeAuthApi({this.loginResponse, this.loginError, this.meUser, this.meError})
      : super(Dio());

  final AuthResponse? loginResponse;
  final Object? loginError;
  final UserDto? meUser;
  final Object? meError;

  @override
  Future<AuthResponse> login({required String username, required String password}) async {
    if (loginError != null) throw loginError!;
    return loginResponse!;
  }

  @override
  Future<UserDto> getMe() async {
    if (meError != null) throw meError!;
    return meUser!;
  }
}

class FakeSecureStorageService extends SecureStorageService {
  FakeSecureStorageService();

  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}

const userDto = UserDto(
  id: 1,
  username: 'emilys',
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@dummyjson.com',
);

void main() {
  test('login stores the token and returns the user', () async {
    final storage = FakeSecureStorageService();
    final api = FakeAuthApi(
      loginResponse: AuthResponse(accessToken: 'token-123', user: userDto),
    );
    final repository = AuthRepositoryImpl(api, storage);

    final user = await repository.login(username: 'emilys', password: 'emilyspass');

    expect(user.username, 'emilys');
    expect(await storage.read(AppConstants.authTokenKey), 'token-123');
  });

  test('restoreSession returns null when there is no stored token', () async {
    final repository = AuthRepositoryImpl(FakeAuthApi(), FakeSecureStorageService());

    final user = await repository.restoreSession();

    expect(user, isNull);
  });

  test('restoreSession deletes the token on a 401 response', () async {
    final storage = FakeSecureStorageService();
    await storage.write(AppConstants.authTokenKey, 'expired-token');
    final api = FakeAuthApi(
      meError: const AppException(AppErrorType.unauthorized, 'No autorizado.'),
    );
    final repository = AuthRepositoryImpl(api, storage);

    final user = await repository.restoreSession();

    expect(user, isNull);
    expect(await storage.read(AppConstants.authTokenKey), isNull);
  });
}
