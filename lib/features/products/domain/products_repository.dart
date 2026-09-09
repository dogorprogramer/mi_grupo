import 'products_page.dart';

abstract class ProductsRepository {
  Future<ProductsPage> getProducts({required int limit, required int skip});
}
