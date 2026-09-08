import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/app/app.dart';
import 'package:mi_grupo/features/auth/data/auth_providers.dart';
import 'package:mi_grupo/features/auth/domain/auth_repository.dart';
import 'package:mi_grupo/features/auth/domain/user.dart';
import 'package:mi_grupo/features/auth/presentation/home_screen.dart';
import 'package:mi_grupo/features/auth/presentation/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restoreResult, this.loginResult});

  User? restoreResult;
  User? loginResult;

  @override
  Future<User?> restoreSession() async => restoreResult;

  @override
  Future<User> login({required String username, required String password}) async =>
      loginResult!;

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
  testWidgets('unauthenticated user is redirected to the login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(restoreResult: null),
          ),
        ],
        child: const MiGrupoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('authenticated user lands on the home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(restoreResult: user),
          ),
        ],
        child: const MiGrupoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('login success navigates to the home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(restoreResult: null, loginResult: user),
          ),
        ],
        child: const MiGrupoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'emilys');
    await tester.enterText(find.byType(TextFormField).at(1), 'emilyspass');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
