import '../domain/product.dart';

class ProductsState {
  const ProductsState({
    required this.products,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Product> products;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  bool get isEmpty => products.isEmpty;
}
