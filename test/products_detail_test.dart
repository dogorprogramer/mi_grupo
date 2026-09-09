import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/features/products/data/products_providers.dart';
import 'package:mi_grupo/features/products/domain/category.dart';
import 'package:mi_grupo/features/products/domain/product.dart';
import 'package:mi_grupo/features/products/domain/product_query.dart';
import 'package:mi_grupo/features/products/domain/products_page.dart';
import 'package:mi_grupo/features/products/domain/products_repository.dart';

class FakeProductsRepository implements ProductsRepository {
  FakeProductsRepository({this.product, this.error});

  Product? product;
  Object? error;

  @override
  Future<Product> getProductById(int id) async {
    if (error != null) throw error!;
    return product!;
  }

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

void main() {
  test('detail provider loads a product', () async {
    final container = ProviderContainer(
      overrides: [
        productsRepositoryProvider.overrideWithValue(
          FakeProductsRepository(product: product),
        ),
      ],
    );
    addTearDown(container.dispose);

    final loaded = await container.read(productDetailProvider(1).future);

    expect(loaded.id, 1);
    expect(loaded.title, 'iPhone 9');
  });

  test('detail provider surfaces a not-found error', () async {
    final container = ProviderContainer(
      overrides: [
        productsRepositoryProvider.overrideWithValue(
          FakeProductsRepository(
            error: const AppException(
              AppErrorType.notFound,
              'Producto no encontrado.',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(productDetailProvider(999));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(productDetailProvider(999));
    expect(state.hasError, isTrue);
    final error = state.error;
    expect(error, isA<AppException>());
    expect((error as AppException).message, 'Producto no encontrado.');
  });

  test('retry reloads the detail after invalidation', () async {
    final repo = FakeProductsRepository(
      error: const AppException(AppErrorType.notFound, 'Producto no encontrado.'),
    );
    final container = ProviderContainer(
      overrides: [
        productsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    container.read(productDetailProvider(1));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(productDetailProvider(1)).hasError, isTrue);

    repo.product = product;
    repo.error = null;
    container.invalidate(productDetailProvider(1));

    final loaded = await container.read(productDetailProvider(1).future);

    expect(loaded.id, 1);
  });
}
