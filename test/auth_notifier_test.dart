import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/features/auth/data/auth_providers.dart';
import 'package:mi_grupo/features/auth/domain/auth_repository.dart';
import 'package:mi_grupo/features/auth/domain/user.dart';
import 'package:mi_grupo/features/auth/presentation/auth_notifier.dart';
import 'package:mi_grupo/features/auth/presentation/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.restoreResult,
    this.restoreError,
    this.loginResult,
    this.loginError,
  });

  User? restoreResult;
  Object? restoreError;
  User? loginResult;
  Object? loginError;

  @override
  Future<User?> restoreSession() async {
    if (restoreError != null) throw restoreError!;
    return restoreResult;
  }

  @override
  Future<User> login({required String username, required String password}) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<void> logout() async {}
}

const user = User(
  id: 1,
  username: 'emilys',
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@dummyjson.com',
);

void main() {
  test('restoreSession with a valid token authenticates the user', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreResult: user),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);

    expect(container.read(authStateProvider).value, isA<AuthAuthenticated>());
  });

  test('restoreSession without a stored token leaves unauthenticated', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreResult: null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);

    expect(container.read(authStateProvider).value, isA<AuthUnauthenticated>());
  });

  test('restoreSession with an invalid token leaves unauthenticated', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            restoreError: const AppException(
              AppErrorType.unauthorized,
              'No autorizado.',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);

    expect(container.read(authStateProvider).value, isA<AuthUnauthenticated>());
  });

  test('login success authenticates the user', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreResult: null, loginResult: user),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);

    await container
        .read(authStateProvider.notifier)
        .login(username: 'emilys', password: 'emilyspass');

    expect(container.read(authStateProvider).value, isA<AuthAuthenticated>());
  });

  test('login failure surfaces a friendly error and stays unauthenticated', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            restoreResult: null,
            loginError: const AppException(
              AppErrorType.unauthorized,
              'No autorizado. Verifica tus credenciales.',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);

    await container
        .read(authStateProvider.notifier)
        .login(username: 'emilys', password: 'wrong');

    final state = container.read(authStateProvider).value;
    expect(state, isA<AuthError>());
    expect((state as AuthError).message, contains('No autorizado'));
  });

  test('logout returns to unauthenticated state', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreResult: user),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);

    await container.read(authStateProvider.notifier).logout();

    expect(container.read(authStateProvider).value, isA<AuthUnauthenticated>());
  });
}
