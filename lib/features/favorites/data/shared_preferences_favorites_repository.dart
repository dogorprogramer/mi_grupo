import 'dart:convert';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/preferences_service.dart';
import '../../products/domain/product.dart';
import '../../products/data/models/product_dto.dart';
import '../domain/favorites_repository.dart';

class SharedPreferencesFavoritesRepository implements FavoritesRepository {
  SharedPreferencesFavoritesRepository(this._preferences);

  final PreferencesService _preferences;

  @override
  Future<List<Product>> load() async {
    final raw = _preferences.getString(AppConstants.favoritesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ProductDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(List<Product> favorites) async {
    final raw = jsonEncode(
      favorites.map((p) => ProductDto.fromDomain(p).toJson()).toList(),
    );
    await _preferences.setString(AppConstants.favoritesKey, raw);
  }
}
