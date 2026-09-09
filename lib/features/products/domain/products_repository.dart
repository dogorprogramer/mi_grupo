import 'category.dart';
import 'product.dart';
import 'product_query.dart';
import 'products_page.dart';

abstract class ProductsRepository {
  Future<ProductsPage> getProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  });

  Future<Product> getProductById(int id);

  Future<List<Category>> getCategories();
}
