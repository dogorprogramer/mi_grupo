import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/storage_providers.dart';
import '../domain/favorites_repository.dart';
import 'shared_preferences_favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final preferences = ref.watch(preferencesServiceProvider);
  return SharedPreferencesFavoritesRepository(preferences);
});
