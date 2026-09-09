import '../../products/domain/product.dart';
import '../domain/favorites_repository.dart';

class InMemoryFavoritesRepository implements FavoritesRepository {
  List<Product> _favorites = const [];

  @override
  Future<List<Product>> load() async => List.of(_favorites);

  @override
  Future<void> save(List<Product> favorites) async {
    _favorites = List.of(favorites);
  }
}
