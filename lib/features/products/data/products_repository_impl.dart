import '../domain/category.dart';
import '../domain/product.dart';
import '../domain/product_query.dart';
import '../domain/products_page.dart';
import '../domain/products_repository.dart';
import 'products_api.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._api);

  final ProductsApi _api;

  @override
  Future<ProductsPage> getProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) async {
    final response = await _api.fetchProducts(query: query, limit: limit, skip: skip);
    return response.toDomain();
  }

  @override
  Future<Product> getProductById(int id) async {
    final dto = await _api.getProductById(id);
    return dto.toDomain();
  }

  @override
  Future<List<Category>> getCategories() async {
    final categories = await _api.getCategories();
    return categories.map((e) => e.toDomain()).toList();
  }
}
