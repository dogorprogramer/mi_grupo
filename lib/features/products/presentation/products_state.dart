import '../domain/category.dart';
import '../domain/product.dart';

class ProductsState {
  const ProductsState({
    required this.products,
    required this.hasMore,
    this.searchQuery = '',
    this.category,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Product> products;
  final bool hasMore;
  final String searchQuery;
  final Category? category;
  final bool isLoadingMore;
  final String? loadMoreError;

  bool get isEmpty => products.isEmpty;
  bool get isSearching => searchQuery.isNotEmpty;
  bool get hasCategory => category != null;
}
