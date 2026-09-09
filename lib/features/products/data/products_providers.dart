import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/network_provider.dart';
import '../domain/products_repository.dart';
import 'products_api.dart';
import 'products_repository_impl.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProductsRepositoryImpl(ProductsApi(dio));
});
