import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/products_providers.dart';
import 'products_state.dart';

class ProductsNotifier extends AsyncNotifier<ProductsState> {
  static const _pageSize = 20;

  int _skip = 0;

  @override
  Future<ProductsState> build() async {
    _skip = 0;
    final page = await ref
        .read(productsRepositoryProvider)
        .getProducts(limit: _pageSize, skip: 0);
    _skip = page.skip + page.products.length;
    return ProductsState(
      products: page.products,
      hasMore: _skip < page.total,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    state = AsyncData(ProductsState(
      products: current.products,
      hasMore: current.hasMore,
      isLoadingMore: true,
    ));

    try {
      final page = await ref
          .read(productsRepositoryProvider)
          .getProducts(limit: _pageSize, skip: _skip);
      _skip = page.skip + page.products.length;
      state = AsyncData(ProductsState(
        products: [...current.products, ...page.products],
        hasMore: _skip < page.total,
      ));
    } on AppException catch (e) {
      state = AsyncData(ProductsState(
        products: current.products,
        hasMore: current.hasMore,
        loadMoreError: e.message,
      ));
    } catch (_) {
      state = AsyncData(ProductsState(
        products: current.products,
        hasMore: current.hasMore,
        loadMoreError: 'Ocurrió un error inesperado.',
      ));
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    _skip = 0;
    try {
      final page = await ref
          .read(productsRepositoryProvider)
          .getProducts(limit: _pageSize, skip: 0);
      _skip = page.skip + page.products.length;
      state = AsyncData(ProductsState(
        products: page.products,
        hasMore: _skip < page.total,
      ));
    } on AppException catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (_) {
      state = AsyncError(
        const AppException(AppErrorType.unexpected, 'Ocurrió un error inesperado.'),
        StackTrace.current,
      );
    }
  }
}

final productsStateProvider =
    AsyncNotifierProvider<ProductsNotifier, ProductsState>(ProductsNotifier.new);
