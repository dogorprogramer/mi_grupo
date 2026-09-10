import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/app/app.dart';
import 'package:mi_grupo/features/auth/data/auth_providers.dart';
import 'package:mi_grupo/features/auth/domain/auth_repository.dart';
import 'package:mi_grupo/features/auth/domain/user.dart';
import 'package:mi_grupo/features/auth/presentation/current_user_provider.dart';
import 'package:mi_grupo/features/favorites/data/favorites_providers.dart';
import 'package:mi_grupo/features/favorites/data/in_memory_favorites_repository.dart';
import 'package:mi_grupo/features/products/data/products_providers.dart';
import 'package:mi_grupo/features/products/domain/category.dart';
import 'package:mi_grupo/features/products/domain/product.dart';
import 'package:mi_grupo/features/products/domain/product_query.dart';
import 'package:mi_grupo/features/products/domain/products_page.dart';
import 'package:mi_grupo/features/products/domain/products_repository.dart';
import 'package:mi_grupo/features/profile/presentation/profile_screen.dart';

const userWithImage = User(
  id: 2,
  username: 'michaelw',
  firstName: 'Michael',
  lastName: 'Williams',
  email: 'michael@x.com',
  image: 'https://dummyjson.com/icon/michaelw/128',
);

const userWithoutImage = User(
  id: 1,
  username: 'emilys',
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@x.com',
);

class FakeAuthRepository implements AuthRepository {
  @override
  Future<User?> restoreSession() async => userWithImage;

  @override
  Future<User> login({required String username, required String password}) async =>
      userWithImage;

  @override
  Future<void> logout() async {}
}

class FakeProductsRepository implements ProductsRepository {
  @override
  Future<ProductsPage> getProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) async =>
      const ProductsPage(products: [], total: 0, skip: 0, limit: 0);

  @override
  Future<Product> getProductById(int id) async => throw UnimplementedError();

  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<void> deleteProduct(int id) async {}
}

Future<void> pumpProfile(WidgetTester tester, User? user) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentUserProvider.overrideWithValue(user)],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the user full name', (tester) async {
    await pumpProfile(tester, userWithImage);

    expect(find.text('Michael Williams'), findsOneWidget);
  });

  testWidgets('shows the user email', (tester) async {
    await pumpProfile(tester, userWithImage);

    expect(find.text('michael@x.com'), findsOneWidget);
  });

  testWidgets('shows an avatar when the image exists', (tester) async {
    await pumpProfile(tester, userWithImage);

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isNotNull);
  });

  testWidgets('falls back to initials when there is no image', (tester) async {
    await pumpProfile(tester, userWithoutImage);

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isNull);
    expect(find.text('EJ'), findsOneWidget);
  });

  testWidgets('shows a safe state when there is no authenticated user', (tester) async {
    await pumpProfile(tester, null);

    expect(find.text('No hay sesión activa.'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('navigates to the profile from the products screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          productsRepositoryProvider.overrideWithValue(FakeProductsRepository()),
          favoritesRepositoryProvider.overrideWithValue(
            InMemoryFavoritesRepository(),
          ),
        ],
        child: const MiGrupoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Michael Williams'), findsOneWidget);
  });
}
