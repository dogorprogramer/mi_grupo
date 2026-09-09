import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../favorites/presentation/favorites_notifier.dart';
import '../data/products_providers.dart';
import '../domain/product.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailError(
          message: _messageFrom(error),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) => _DetailContent(product: product),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesStateProvider);
    final isFavorite = favorites.any((p) => p.id == product.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                product.images.isNotEmpty ? product.images.first : product.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 64),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(product.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                product.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, product.category),
              if (product.brand != null) _chip(context, product.brand!),
              _chip(context, 'Stock: ${product.stock}'),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(favoritesStateProvider.notifier).toggle(product),
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            label: Text(isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos'),
          ),
          const SizedBox(height: 16),
          Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(product.description),
          if (product.images.length > 1) ...[
            const SizedBox(height: 16),
            Text('Imágenes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: product.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.images[index],
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Chip(label: Text(label));
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

String _messageFrom(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return 'No pudimos cargar el producto. Intenta nuevamente.';
}
