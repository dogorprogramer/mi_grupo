import '../../products/domain/product.dart';

class FavoritesState {
  const FavoritesState({required this.favorites, required this.isHydrated});

  final List<Product> favorites;
  final bool isHydrated;

  bool get isEmpty => favorites.isEmpty;

  bool isFavorite(int id) => favorites.any((product) => product.id == id);
}
