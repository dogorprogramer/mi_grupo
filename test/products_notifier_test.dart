import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/features/products/data/products_providers.dart';
import 'package:mi_grupo/features/products/domain/product.dart';
import 'package:mi_grupo/features/products/domain/products_page.dart';
import 'package:mi_grupo/features/products/domain/products_repository.dart';
import 'package:mi_grupo/features/products/presentation/products_notifier.dart';

class FakeProductsRepository implements ProductsRepository {
  FakeProductsRepository({this.pages, this.error});

  List<ProductsPage>? pages;
  Object? error;
  bool failNext = false;
  Completer<ProductsPage>? pending;
  int callCount = 0;

  @override
  Future<ProductsPage> getProducts({required int limit, required int skip}) async {
    callCount++;
    if (pending != null) {
      return pending!.future;
    }
    if (failNext) {
      failNext = false;
      throw const AppException(AppErrorType.server, 'Error de servidor.');
    }
    if (error != null) {
      throw error!;
    }
    if (pages == null || pages!.isEmpty) {
      return ProductsPage(products: const [], total: 0, skip: skip, limit: limit);
    }
    return pages!.firstWhere((p) => p.skip == skip, orElse: () => pages!.last);
  }
}

ProductsPage page({required int skip, required int count, required int total}) {
  return ProductsPage(
    products: List.generate(
      count,
      (i) => Product(
        id: skip + i,
        title: 'Product ${skip + i}',
        description: 'desc',
        category: 'cat',
        price: 10.0,
        rating: 4.0,
        stock: 5,
        thumbnail: 'https://dummyjson.com/x.png',
        images: const [],
      ),
    ),
    total: total,
    skip: skip,
    limit: count,
  );
}

ProviderContainer makeContainer(FakeProductsRepository repo) {
  final container = ProviderContainer(
    overrides: [
      productsRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('loads the first page on build', () async {
    final repo = FakeProductsRepository(pages: [page(skip: 0, count: 20, total: 40)]);
    final container = makeContainer(repo);

    await container.read(productsStateProvider.future);

    final state = container.read(productsStateProvider).value!;
    expect(state.products, hasLength(20));
    expect(state.hasMore, isTrue);
  });

  test('loadMore appends the next page', () async {
    final repo = FakeProductsRepository(
      pages: [page(skip: 0, count: 20, total: 40), page(skip: 20, count: 20, total: 40)],
    );
    final container = makeContainer(repo);

    await container.read(productsStateProvider.future);
    await container.read(productsStateProvider.notifier).loadMore();

    final state = container.read(productsStateProvider).value!;
    expect(state.products, hasLength(40));
    expect(state.hasMore, isFalse);
  });

  test('does not fire a duplicate request while loadMore is in progress', () async {
    final repo = FakeProductsRepository(pages: [page(skip: 0, count: 20, total: 40)]);
    final container = makeContainer(repo);

    await container.read(productsStateProvider.future);
    expect(repo.callCount, 1);

    repo.pending = Completer<ProductsPage>();
    final firstLoadMore = container.read(productsStateProvider.notifier).loadMore();
    await Future<void>.delayed(Duration.zero);
    expect(repo.callCount, 2);

    await container.read(productsStateProvider.notifier).loadMore();
    expect(repo.callCount, 2);

    repo.pending!.complete(page(skip: 20, count: 20, total: 40));
    await firstLoadMore;

    final state = container.read(productsStateProvider).value!;
    expect(state.products, hasLength(40));
  });

  test('loadMore is a no-op when there are no more products', () async {
    final repo = FakeProductsRepository(pages: [page(skip: 0, count: 20, total: 20)]);
    final container = makeContainer(repo);

    await container.read(productsStateProvider.future);
    expect(repo.callCount, 1);

    await container.read(productsStateProvider.notifier).loadMore();

    expect(repo.callCount, 1);
    expect(container.read(productsStateProvider).value!.hasMore, isFalse);
  });

  test('an empty first page results in an empty state', () async {
    final repo = FakeProductsRepository(pages: [page(skip: 0, count: 0, total: 0)]);
    final container = makeContainer(repo);

    await container.read(productsStateProvider.future);

    final state = container.read(productsStateProvider).value!;
    expect(state.isEmpty, isTrue);
    expect(state.hasMore, isFalse);
  });

  test('initial load error emits an AsyncError', () async {
    final repo = FakeProductsRepository(
      error: const AppException(AppErrorType.server, 'Error de servidor.'),
    );
    final container = makeContainer(repo);

    container.read(productsStateProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(productsStateProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AppException>());
  });

  test('loadMore error keeps the products and sets loadMoreError', () async {
    final repo = FakeProductsRepository(pages: [page(skip: 0, count: 20, total: 40)]);
    final container = makeContainer(repo);

    await container.read(productsStateProvider.future);
    repo.failNext = true;

    await container.read(productsStateProvider.notifier).loadMore();

    final state = container.read(productsStateProvider).value!;
    expect(state.products, hasLength(20));
    expect(state.loadMoreError, 'Error de servidor.');
    expect(state.isLoadingMore, isFalse);
  });
}
