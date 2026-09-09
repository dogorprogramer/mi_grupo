import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

ProviderContainer makeContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('initially has no favorites', () async {
    final container = makeContainer();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(favoritesStateProvider), isEmpty);
  });

  test('toggle adds a favorite', () async {
    final container = makeContainer();
    final notifier = container.read(favoritesStateProvider.notifier);

    await notifier.toggle(makeProduct(1));

    final favorites = container.read(favoritesStateProvider);
    expect(favorites, hasLength(1));
    expect(favorites.first.id, 1);
    expect(notifier.isFavorite(1), isTrue);
  });

  test('toggle again removes a favorite', () async {
    final container = makeContainer();
    final notifier = container.read(favoritesStateProvider.notifier);

    await notifier.toggle(makeProduct(1));
    await notifier.toggle(makeProduct(1));

    expect(container.read(favoritesStateProvider), isEmpty);
    expect(notifier.isFavorite(1), isFalse);
  });

  test('supports multiple favorites', () async {
    final container = makeContainer();
    final notifier = container.read(favoritesStateProvider.notifier);

    await notifier.toggle(makeProduct(1));
    await notifier.toggle(makeProduct(2));

    expect(container.read(favoritesStateProvider), hasLength(2));
    expect(notifier.isFavorite(1), isTrue);
    expect(notifier.isFavorite(2), isTrue);
  });

  test('state is the same single source for all readers', () async {
    final container = makeContainer();
    final notifier = container.read(favoritesStateProvider.notifier);
    await notifier.toggle(makeProduct(1));

    expect(
      container.read(favoritesStateProvider).map((e) => e.id).toList(),
      [1],
    );
  });
}
