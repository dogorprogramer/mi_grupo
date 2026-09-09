import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/features/favorites/presentation/favorites_screen.dart';

void main() {
  testWidgets('favorites screen shows an empty state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tienes favoritos.'), findsOneWidget);
  });
}
