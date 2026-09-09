import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../favorites/presentation/favorites_notifier.dart';
import '../data/products_providers.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import 'products_notifier.dart';
import 'products_state.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectCategory(Category? category) {
    _searchController.clear();
    if (category == null) {
      ref.read(productsStateProvider.notifier).clearCategory();
    } else {
      ref.read(productsStateProvider.notifier).selectCategory(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(productsStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiGrupo'),
        actions: [
          IconButton(
            onPressed: () => context.push('/favorites'),
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favoritos',
          ),
          IconButton(
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchField(
            controller: _searchController,
            onChanged: (value) =>
                ref.read(productsStateProvider.notifier).onSearchChanged(value),
          ),
          _CategoryFilter(onSelect: _onSelectCategory),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(productsStateProvider.notifier).refresh(),
              child: asyncState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorView(
                  message: _messageFrom(error),
                  onRetry: () => ref.read(productsStateProvider.notifier).retry(),
                ),
                data: (state) => _ProductsGrid(state: state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar productos',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.onSelect});

  final ValueChanged<Category?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsState = ref.watch(productsStateProvider);
    final selectedSlug = productsState.value?.category?.slug;
    final isSearching = productsState.value?.isSearching ?? false;

    return SizedBox(
      height: 48,
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CategoryError(
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _chip(
              label: 'Todos',
              selected: !isSearching && selectedSlug == null,
              onSelect: onSelect,
              value: null,
            ),
            ...categories.map(
              (cat) => _chip(
                label: cat.name,
                selected: selectedSlug == cat.slug,
                onSelect: onSelect,
                value: cat,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required ValueChanged<Category?> onSelect,
    required Category? value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelect(value),
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Expanded(child: Text('No se pudieron cargar las categorías.')),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ProductsGrid extends ConsumerWidget {
  const _ProductsGrid({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isEmpty) {
      final message = _emptyMessage(state);
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(message)),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          ref.read(productsStateProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(product: state.products[index]),
                childCount: state.products.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _Footer(state: state)),
        ],
      ),
    );
  }

  String _emptyMessage(ProductsState state) {
    if (state.isSearching) {
      return 'No se encontraron productos.';
    }
    if (state.hasCategory) {
      return 'No hay productos en esta categoría.';
    }
    return 'No hay productos.';
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(state.loadMoreError!),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(productsStateProvider.notifier).loadMore(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('No hay más productos.')),
      );
    }
    return const SizedBox(height: 8);
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesStateProvider);
    final isFavorite = favorites.any((p) => p.id == product.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                      onPressed: () =>
                          ref.read(favoritesStateProvider.notifier).toggle(product),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(product.rating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
  return 'Ocurrió un error inesperado.';
}
