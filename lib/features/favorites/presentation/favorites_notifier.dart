import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product.dart';
import '../data/favorites_providers.dart';
import '../domain/favorites_repository.dart';

class FavoritesNotifier extends Notifier<List<Product>> {
  FavoritesRepository get _repository => ref.read(favoritesRepositoryProvider);

  @override
  List<Product> build() => const [];

  bool isFavorite(int id) => state.any((product) => product.id == id);

  Future<void> toggle(Product product) async {
    final favorites = List<Product>.from(state);
    final index = favorites.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(product);
    }
    state = favorites;
    await _repository.save(favorites);
  }
}

final favoritesStateProvider =
    NotifierProvider<FavoritesNotifier, List<Product>>(FavoritesNotifier.new);
