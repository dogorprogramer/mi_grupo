import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_grupo/core/constants/app_constants.dart';
import 'package:mi_grupo/core/storage/preferences_service.dart';
import 'package:mi_grupo/features/favorites/data/shared_preferences_favorites_repository.dart';
import 'package:mi_grupo/features/products/domain/product.dart';

Product makeProduct(int id) {
  return Product(
    id: id,
    title: 'Product $id',
    description: 'desc',
    category: 'cat',
    price: 10.0,
    rating: 4.0,
    stock: 5,
    thumbnail: 'https://dummyjson.com/x.png',
    images: const [],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and loads favorites', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPreferencesFavoritesRepository(PreferencesService(prefs));

    await repo.save([makeProduct(1), makeProduct(2)]);

    final loaded = await repo.load();
    expect(loaded.map((e) => e.id).toList(), [1, 2]);
  });

  test('loads empty when nothing is stored', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPreferencesFavoritesRepository(PreferencesService(prefs));

    expect(await repo.load(), isEmpty);
  });

  test('persists between repository instances', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo1 = SharedPreferencesFavoritesRepository(PreferencesService(prefs));
    await repo1.save([makeProduct(1)]);

    final repo2 = SharedPreferencesFavoritesRepository(PreferencesService(prefs));
    expect((await repo2.load()).map((e) => e.id).toList(), [1]);
  });

  test('returns empty on corrupt data', () async {
    SharedPreferences.setMockInitialValues({AppConstants.favoritesKey: 'not-json'});
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPreferencesFavoritesRepository(PreferencesService(prefs));

    expect(await repo.load(), isEmpty);
  });
}
