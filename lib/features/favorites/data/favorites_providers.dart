import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/favorites_repository.dart';
import 'in_memory_favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => InMemoryFavoritesRepository(),
);
