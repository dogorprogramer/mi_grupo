import '../../products/domain/product.dart';

abstract class FavoritesRepository {
  Future<List<Product>> load();

  Future<void> save(List<Product> favorites);
}
