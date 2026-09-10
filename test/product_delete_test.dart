import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
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
import 'package:mi_grupo/features/products/presentation/product_delete_notifier.dart';
import 'package:mi_grupo/features/products/presentation/product_detail_screen.dart';

const product = Product(
  id: 1,
  title: 'iPhone 9',
  description: 'An apple mobile',
  category: 'smartphones',
  price: 549,
  rating: 4.69,
  stock: 94,
  brand: 'Apple',
  thumbnail: 'https://dummyjson.com/iphone.png',
  images: ['https://dummyjson.com/iphone.png'],
);

const adminUser = User(
  id: 2,
  username: 'admin',
  firstName: 'Admin',
  lastName: 'User',
  email: 'admin@x.com',
);

const standardUser = User(
  id: 1,
  username: 'standard',
  firstName: 'Standard',
  lastName: 'User',
  email: 'standard@x.com',
);

class FakeDeleteRepository implements ProductsRepository {
  int deleteCalls = 0;
  Object? deleteError;

  @override
  Future<void> deleteProduct(int id) async {
    deleteCalls++;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<Product> getProductById(int id) async => product;

  @override
  Future<ProductsPage> getProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<Category>> getCategories() async => const [];
}

class FakeDetailRepository implements ProductsRepository {
  FakeDetailRepository();

  @override
  Future<Product> getProductById(int id) async => product;

  @override
  Future<ProductsPage> getProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<void> deleteProduct(int id) async {}
}

ProviderContainer makeDeleteContainer(FakeDeleteRepository repo) {
  final container = ProviderContainer(
    overrides: [
      productsRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ProductDeleteNotifier', () {
    test('delete sets a success state', () async {
      final container = makeDeleteContainer(FakeDeleteRepository());

      await container.read(productDeleteProvider.notifier).delete(1);

      expect(
        container.read(productDeleteProvider).status,
        ProductDeleteStatus.success,
      );
    });

    test('delete surfaces a friendly error message', () async {
      final repo = FakeDeleteRepository()
        ..deleteError = const AppException(
          AppErrorType.server,
          'Ocurrió un error en el servidor.',
        );
      final container = makeDeleteContainer(repo);

      await container.read(productDeleteProvider.notifier).delete(1);

      final state = container.read(productDeleteProvider);
      expect(state.status, ProductDeleteStatus.failure);
      expect(state.errorMessage, 'Ocurrió un error en el servidor.');
    });

    test('does not fire multiple deletes while one is in progress', () async {
      final repo = FakeDeleteRepository();
      final container = makeDeleteContainer(repo);
      final notifier = container.read(productDeleteProvider.notifier);

      final first = notifier.delete(1);
      final second = notifier.delete(1);
      await Future.wait([first, second]);

      expect(repo.deleteCalls, 1);
    });
  });

  group('ProductDetailScreen role UI', () {
    Future<void> pumpDetail(WidgetTester tester, User user) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(user),
            productsRepositoryProvider.overrideWithValue(FakeDetailRepository()),
            favoritesRepositoryProvider.overrideWithValue(
              InMemoryFavoritesRepository(),
            ),
          ],
          child: const MaterialApp(home: ProductDetailScreen(productId: 1)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('admin sees the delete button', (tester) async {
      await pumpDetail(tester, adminUser);

      expect(find.text('Eliminar producto'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('standard user does not see the delete button', (tester) async {
      await pumpDetail(tester, standardUser);

      expect(find.text('Eliminar producto'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('admin sees an error message when delete fails', (tester) async {
      final repo = FakeDeleteRepository()
        ..deleteError = const AppException(
          AppErrorType.server,
          'Ocurrió un error en el servidor.',
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(adminUser),
            productsRepositoryProvider.overrideWithValue(repo),
            favoritesRepositoryProvider.overrideWithValue(
              InMemoryFavoritesRepository(),
            ),
          ],
          child: const MaterialApp(home: ProductDetailScreen(productId: 1)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Eliminar producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Ocurrió un error en el servidor.'), findsOneWidget);
    });
  });
}
