import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/features/favorites/data/favorites_providers.dart';
import 'package:mi_grupo/features/favorites/data/in_memory_favorites_repository.dart';
import 'package:mi_grupo/features/products/domain/product.dart';
import 'package:mi_grupo/features/products/presentation/widgets/product_card.dart';

const product = Product(
  id: 1,
  title: 'Essence Mascara Lash Princess',
  description: 'desc',
  category: 'beauty',
  price: 9.99,
  rating: 2.56,
  stock: 99,
  brand: 'Essence',
  thumbnail: 'https://dummyjson.com/image.png',
  images: ['https://dummyjson.com/image.png'],
);

Future<void> pumpCard(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(
          InMemoryFavoritesRepository(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 162,
              height: 238,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the product information without overflow',
      (tester) async {
    await pumpCard(tester);

    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    expect(find.text('\$9.99'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('toggles the favorite icon', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
