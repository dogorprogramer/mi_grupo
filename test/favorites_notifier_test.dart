import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/features/favorites/data/favorites_providers.dart';
import 'package:mi_grupo/features/favorites/data/in_memory_favorites_repository.dart';
import 'package:mi_grupo/features/favorites/domain/favorites_repository.dart';
import 'package:mi_grupo/features/favorites/presentation/favorites_notifier.dart';
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

ProviderContainer makeContainer({FavoritesRepository? repository}) {
  final container = ProviderContainer(
    overrides: [
      favoritesRepositoryProvider.overrideWithValue(
        repository ?? InMemoryFavoritesRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('hydrates to empty when no data is stored', () async {
    final container = makeContainer();
    container.read(favoritesStateProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(favoritesStateProvider);
    expect(state.isHydrated, isTrue);
    expect(state.isEmpty, isTrue);
  });

  test('hydrates persisted favorites', () async {
    final repository = InMemoryFavoritesRepository();
    await repository.save([makeProduct(1)]);

    final container = makeContainer(repository: repository);
    container.read(favoritesStateProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(favoritesStateProvider);
    expect(state.isHydrated, isTrue);
    expect(state.favorites, hasLength(1));
    expect(state.favorites.first.id, 1);
  });

  test('toggle adds a favorite and persists', () async {
    final repository = InMemoryFavoritesRepository();
    final container = makeContainer(repository: repository);
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(favoritesStateProvider.notifier);
    await notifier.toggle(makeProduct(1));

    expect(container.read(favoritesStateProvider).favorites, hasLength(1));
    expect(await repository.load(), hasLength(1));
    expect(notifier.isFavorite(1), isTrue);
  });

  test('toggle again removes a favorite and persists', () async {
    final repository = InMemoryFavoritesRepository();
    final container = makeContainer(repository: repository);
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(favoritesStateProvider.notifier);
    await notifier.toggle(makeProduct(1));
    await notifier.toggle(makeProduct(1));

    expect(container.read(favoritesStateProvider).isEmpty, isTrue);
    expect(await repository.load(), isEmpty);
    expect(notifier.isFavorite(1), isFalse);
  });

  test('supports multiple favorites', () async {
    final container = makeContainer();
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(favoritesStateProvider.notifier);
    await notifier.toggle(makeProduct(1));
    await notifier.toggle(makeProduct(2));

    expect(container.read(favoritesStateProvider).favorites, hasLength(2));
    expect(notifier.isFavorite(1), isTrue);
    expect(notifier.isFavorite(2), isTrue);
  });
}
