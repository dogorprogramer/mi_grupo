import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../products/domain/product.dart';
import 'favorites_notifier.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favorites.isEmpty
          ? const Center(child: Text('No tienes favoritos.'))
          : ListView.separated(
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = favorites[index];
                return _FavoriteTile(product: product);
              },
            ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image.network(
            product.thumbnail,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image),
          ),
        ),
      ),
      title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
      trailing: IconButton(
        tooltip: 'Quitar de favoritos',
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () => ref.read(favoritesStateProvider.notifier).toggle(product),
      ),
      onTap: () => context.push('/product/${product.id}'),
    );
  }
}
