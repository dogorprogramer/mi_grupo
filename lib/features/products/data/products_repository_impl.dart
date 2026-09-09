import '../domain/products_page.dart';
import '../domain/products_repository.dart';
import 'products_api.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._api);

  final ProductsApi _api;

  @override
  Future<ProductsPage> getProducts({required int limit, required int skip}) async {
    final response = await _api.getProducts(limit: limit, skip: skip);
    return response.toDomain();
  }
}
