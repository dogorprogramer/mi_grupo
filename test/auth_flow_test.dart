import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/app/app.dart';
import 'package:mi_grupo/features/auth/data/auth_providers.dart';
import 'package:mi_grupo/features/auth/domain/auth_repository.dart';
import 'package:mi_grupo/features/auth/domain/user.dart';
import 'package:mi_grupo/features/auth/presentation/login_screen.dart';
import 'package:mi_grupo/features/auth/presentation/splash_screen.dart';
import 'package:mi_grupo/features/products/data/products_providers.dart';
import 'package:mi_grupo/features/products/domain/category.dart';
import 'package:mi_grupo/features/products/domain/product.dart';
import 'package:mi_grupo/features/products/domain/product_query.dart';
import 'package:mi_grupo/features/products/domain/products_page.dart';
import 'package:mi_grupo/features/products/domain/products_repository.dart';
import 'package:mi_grupo/features/products/presentation/products_screen.dart';

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

class FakeProductsRepository implements ProductsRepository {
  @override
  Future<ProductsPage> getProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) async {
    return const ProductsPage(products: [], total: 0, skip: 0, limit: 0);
  }

  @override
  Future<Product> getProductById(int id) async =>
      throw UnimplementedError();

  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<void> deleteProduct(int id) async {}
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
          productsRepositoryProvider.overrideWithValue(FakeProductsRepository()),
        ],
        child: const MiGrupoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('authenticated user lands on the products screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(restoreResult: user),
          ),
          productsRepositoryProvider.overrideWithValue(FakeProductsRepository()),
        ],
        child: const MiGrupoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductsScreen), findsOneWidget);
  });

  testWidgets('login success navigates to the products screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(restoreResult: null, loginResult: user),
          ),
          productsRepositoryProvider.overrideWithValue(FakeProductsRepository()),
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

    expect(find.byType(ProductsScreen), findsOneWidget);
  });

  testWidgets('stays on the login screen while login is in progress', (tester) async {
    final authRepository = SlowLoginAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          productsRepositoryProvider.overrideWithValue(FakeProductsRepository()),
        ],
        child: const MiGrupoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'emilys');
    await tester.enterText(find.byType(TextFormField).at(1), 'emilyspass');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);

    authRepository.complete(user);
    await tester.pumpAndSettle();

    expect(find.byType(ProductsScreen), findsOneWidget);
  });
}

class SlowLoginAuthRepository implements AuthRepository {
  final _completer = Completer<User>();

  @override
  Future<User?> restoreSession() async => null;

  @override
  Future<User> login({required String username, required String password}) =>
      _completer.future;

  @override
  Future<void> logout() async {}

  void complete(User user) => _completer.complete(user);
}
