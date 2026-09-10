import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../../favorites/presentation/favorites_notifier.dart';
import '../data/products_providers.dart';
import '../domain/product.dart';
import 'product_delete_notifier.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(productDeleteProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.productId));
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;
    final deleteState = ref.watch(productDeleteProvider);
    final isDeleting = deleteState.isDeleting;

    ref.listen(productDeleteProvider, (_, next) {
      if (next.status == ProductDeleteStatus.success) {
        _onDeleted();
      } else if (next.status == ProductDeleteStatus.failure) {
        _onDeleteFailed(next.errorMessage);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailError(
          message: _messageFrom(error),
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) => _DetailContent(
          product: product,
          isAdmin: isAdmin,
          isDeleting: isDeleting,
          onDelete: () => _confirmDelete(product),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(productDeleteProvider.notifier).delete(widget.productId);
    }
  }

  void _onDeleted() {
    if (!mounted) {
      return;
    }
    final product = ref.read(productDetailProvider(widget.productId)).value;
    if (product != null && ref.read(favoritesStateProvider).isFavorite(product.id)) {
      ref.read(favoritesStateProvider.notifier).remove(product);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto eliminado.')),
    );
    context.pop();
  }

  void _onDeleteFailed(String? message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'No fue posible eliminar el producto. Intenta nuevamente.',
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.product,
    required this.isAdmin,
    required this.isDeleting,
    required this.onDelete,
  });

  final Product product;
  final bool isAdmin;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
          _FavoriteButton(product: product),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isDeleting ? null : onDelete,
              icon: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text('Eliminar producto'),
            ),
          ],
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

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesStateProvider);
    final isFavorite = favoritesState.isFavorite(product.id);

    return FilledButton.tonalIcon(
      onPressed: () => ref.read(favoritesStateProvider.notifier).toggle(product),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      label: Text(isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos'),
    );
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
