import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/products_providers.dart';
import '../domain/category.dart';
import 'products_notifier.dart';
import 'products_state.dart';
import 'widgets/product_card.dart';

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
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
          ),
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
                loading: () => const _ProductsGridSkeleton(),
                error: (error, _) => AppErrorView(
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
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
        loading: () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          children: List.generate(
            5,
            (index) => const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: ShimmerBox(
                width: 88,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
              ),
            ),
          ),
        ),
        error: (_, _) => _CategoryError(
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
      padding: const EdgeInsets.only(right: AppSpacing.sm),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyView(
              message: _emptyMessage(state),
              icon: state.isSearching
                  ? Icons.search_off
                  : Icons.inventory_2_outlined,
            ),
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
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(product: state.products[index]),
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

class _ProductsGridSkeleton extends StatelessWidget {
  const _ProductsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _ProductCardSkeleton(),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: ShimmerBox(borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(height: 12),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(height: 12, width: 80),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(height: 12, width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(state.loadMoreError!),
            const SizedBox(height: AppSpacing.sm),
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
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text('No hay más productos.')),
      );
    }
    return const SizedBox(height: AppSpacing.sm);
  }
}

String _messageFrom(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return 'Ocurrió un error inesperado.';
}
