import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product.dart';
import '../data/favorites_providers.dart';
import '../domain/favorites_repository.dart';
import 'favorites_state.dart';

class FavoritesNotifier extends Notifier<FavoritesState> {
  FavoritesRepository get _repository => ref.read(favoritesRepositoryProvider);

  @override
  FavoritesState build() {
    _hydrate();
    return const FavoritesState(favorites: [], isHydrated: false);
  }

  Future<void> _hydrate() async {
    final favorites = await _repository.load();
    if (!state.isHydrated) {
      state = FavoritesState(favorites: favorites, isHydrated: true);
    }
  }

  bool isFavorite(int id) => state.isFavorite(id);

  Future<void> toggle(Product product) async {
    if (!state.isHydrated) {
      await _hydrate();
    }
    final favorites = List<Product>.from(state.favorites);
    final index = favorites.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(product);
    }
    state = FavoritesState(favorites: favorites, isHydrated: true);
    await _repository.save(favorites);
  }
}

final favoritesStateProvider =
    NotifierProvider<FavoritesNotifier, FavoritesState>(FavoritesNotifier.new);
