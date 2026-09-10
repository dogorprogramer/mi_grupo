import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/products_providers.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import '../domain/product_query.dart';
import '../domain/products_page.dart';
import 'products_state.dart';

class ProductsNotifier extends AsyncNotifier<ProductsState> {
  static const _pageSize = 20;
  static const _debounceDuration = Duration(milliseconds: 400);

  int _skip = 0;
  String _searchQuery = '';
  Category? _category;
  int _generation = 0;
  bool _isRefreshing = false;
  Timer? _debounce;

  ProductQuery get _query => ProductQuery(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _category?.slug,
      );

  @override
  Future<ProductsState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    _skip = 0;
    final page = await _fetchFirstPage();
    return _state(products: page.products, hasMore: _skip < page.total);
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _setSearch(value));
  }

  Future<void> selectCategory(Category category) async {
    _debounce?.cancel();
    if (category.slug == _category?.slug && _searchQuery.isEmpty) {
      return;
    }
    _category = category;
    _searchQuery = '';
    await _reload();
  }

  Future<void> clearCategory() async {
    _debounce?.cancel();
    if (_category == null && _searchQuery.isEmpty) {
      return;
    }
    _category = null;
    _searchQuery = '';
    await _reload();
  }

  Future<void> retry() => _reload();

  Future<void> refresh() async {
    if (_isRefreshing || state is AsyncLoading) {
      return;
    }
    _isRefreshing = true;
    final gen = ++_generation;
    _skip = 0;
    try {
      final page = await _fetchFirstPage();
      if (gen != _generation) return;
      state = AsyncData(_state(products: page.products, hasMore: _skip < page.total));
    } on AppException catch (e) {
      if (gen != _generation) return;
      state = AsyncError(e, StackTrace.current);
    } catch (_) {
      if (gen != _generation) return;
      state = AsyncError(
        const AppException(AppErrorType.unexpected, 'Ocurrió un error inesperado.'),
        StackTrace.current,
      );
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore || _isRefreshing) {
      return;
    }
    final gen = _generation;
    state = AsyncData(_state(
      products: current.products,
      hasMore: current.hasMore,
      isLoadingMore: true,
    ));
    try {
      final page = await ref
          .read(productsRepositoryProvider)
          .getProducts(query: _query, limit: _pageSize, skip: _skip);
      if (gen != _generation) return;
      _skip = page.skip + page.products.length;
      state = AsyncData(_state(
        products: [...current.products, ...page.products],
        hasMore: _skip < page.total,
      ));
    } on AppException catch (e) {
      if (gen != _generation) return;
      state = AsyncData(_state(
        products: current.products,
        hasMore: current.hasMore,
        loadMoreError: e.message,
      ));
    } catch (_) {
      if (gen != _generation) return;
      state = AsyncData(_state(
        products: current.products,
        hasMore: current.hasMore,
        loadMoreError: 'Ocurrió un error inesperado.',
      ));
    }
  }

  Future<void> _setSearch(String value) async {
    _debounce?.cancel();
    final text = value.trim();
    if (text == _searchQuery) {
      return;
    }
    _searchQuery = text;
    _category = null;
    await _reload();
  }

  Future<void> _reload() async {
    final gen = ++_generation;
    _skip = 0;
    state = const AsyncLoading();
    try {
      final page = await _fetchFirstPage();
      if (gen != _generation) return;
      state = AsyncData(_state(products: page.products, hasMore: _skip < page.total));
    } on AppException catch (e) {
      if (gen != _generation) return;
      state = AsyncError(e, StackTrace.current);
    } catch (_) {
      if (gen != _generation) return;
      state = AsyncError(
        const AppException(AppErrorType.unexpected, 'Ocurrió un error inesperado.'),
        StackTrace.current,
      );
    }
  }

  Future<ProductsPage> _fetchFirstPage() async {
    final page = await ref.read(productsRepositoryProvider).getProducts(
          query: _query,
          limit: _pageSize,
          skip: 0,
        );
    _skip = page.skip + page.products.length;
    return page;
  }

  ProductsState _state({
    required List<Product> products,
    required bool hasMore,
    bool isLoadingMore = false,
    String? loadMoreError,
  }) {
    return ProductsState(
      products: products,
      hasMore: hasMore,
      searchQuery: _searchQuery,
      category: _category,
      isLoadingMore: isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

final productsStateProvider =
    AsyncNotifierProvider<ProductsNotifier, ProductsState>(ProductsNotifier.new);
