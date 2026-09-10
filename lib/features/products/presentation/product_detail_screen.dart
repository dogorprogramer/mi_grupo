import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/shimmer_box.dart';
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
        loading: () => const _ProductDetailSkeleton(),
        error: (error, _) => AppErrorView(
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

class _DetailContent extends StatefulWidget {
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
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  int _selectedImage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final images =
        product.images.isNotEmpty ? product.images : <String>[product.thumbnail];
    final safeIndex = _selectedImage.clamp(0, images.length - 1);
    final mainImage = images[safeIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'product-image-${product.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Image.network(
                    mainImage,
                    key: ValueKey<String>(mainImage),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final selected = index == safeIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedImage = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                        child: Image.network(
                          images[index],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(product.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.star, size: 18, color: AppColors.rating),
              const SizedBox(width: AppSpacing.xs),
              Text(
                product.rating.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _chip(context, product.category),
              if (product.brand != null) _chip(context, product.brand!),
              _chip(context, 'Stock: ${product.stock}'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FavoriteButton(product: product),
          if (widget.isAdmin) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: widget.isDeleting ? null : widget.onDelete,
              icon: widget.isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text('Eliminar producto'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Descripción', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(product.description),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Chip(label: Text(label));
  }
}

class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(
            height: 280,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 22, width: 220),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: 18, width: 120),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(
            height: 40,
            width: 180,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 12),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: 12),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: 12, width: 200),
        ],
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesStateProvider).isFavorite(product.id);

    return FilledButton.tonalIcon(
      onPressed: () =>
          ref.read(favoritesStateProvider.notifier).toggle(product),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      label: Text(isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos'),
    );
  }
}

String _messageFrom(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return 'No pudimos cargar el producto. Intenta nuevamente.';
}
