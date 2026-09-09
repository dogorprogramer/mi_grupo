import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/products_providers.dart';

enum ProductDeleteStatus { idle, deleting, success, failure }

class ProductDeleteState {
  const ProductDeleteState({
    required this.status,
    this.errorMessage,
  });

  final ProductDeleteStatus status;
  final String? errorMessage;

  bool get isDeleting => status == ProductDeleteStatus.deleting;
}

class ProductDeleteNotifier extends Notifier<ProductDeleteState> {
  @override
  ProductDeleteState build() => const ProductDeleteState(status: ProductDeleteStatus.idle);

  void reset() {
    state = const ProductDeleteState(status: ProductDeleteStatus.idle);
  }

  Future<void> delete(int productId) async {
    if (state.status == ProductDeleteStatus.deleting) {
      return;
    }
    state = const ProductDeleteState(status: ProductDeleteStatus.deleting);
    try {
      await ref.read(productsRepositoryProvider).deleteProduct(productId);
      state = const ProductDeleteState(status: ProductDeleteStatus.success);
    } on AppException catch (e) {
      state = ProductDeleteState(
        status: ProductDeleteStatus.failure,
        errorMessage: e.message,
      );
    } catch (_) {
      state = const ProductDeleteState(
        status: ProductDeleteStatus.failure,
        errorMessage: 'No fue posible eliminar el producto. Intenta nuevamente.',
      );
    }
  }
}

final productDeleteProvider =
    NotifierProvider<ProductDeleteNotifier, ProductDeleteState>(
  ProductDeleteNotifier.new,
);
