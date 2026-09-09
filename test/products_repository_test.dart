import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/features/products/data/models/category_dto.dart';
import 'package:mi_grupo/features/products/data/models/product_dto.dart';
import 'package:mi_grupo/features/products/data/models/products_response.dart';
import 'package:mi_grupo/features/products/data/products_api.dart';
import 'package:mi_grupo/features/products/data/products_repository_impl.dart';
import 'package:mi_grupo/features/products/domain/product_query.dart';

class FakeProductsApi extends ProductsApi {
  FakeProductsApi({
    this.response,
    this.error,
    this.categories,
    this.product,
    this.productError,
  }) : super(Dio());

  final ProductsResponse? response;
  final Object? error;
  final List<CategoryDto>? categories;
  final ProductDto? product;
  final Object? productError;

  @override
  Future<ProductsResponse> fetchProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) async {
    if (error != null) throw error!;
    return response!;
  }

  @override
  Future<List<CategoryDto>> getCategories() async {
    if (error != null) throw error!;
    return categories ?? const [];
  }

  @override
  Future<ProductDto> getProductById(int id) async {
    if (productError != null) throw productError!;
    return product!;
  }

  @override
  Future<void> deleteProduct(int id) async {
    if (productError != null) throw productError!;
  }
}

const productDto = ProductDto(
  id: 1,
  title: 'iPhone 9',
  description: 'desc',
  category: 'smartphones',
  price: 549,
  rating: 4.69,
  stock: 94,
  brand: 'Apple',
  thumbnail: 'https://dummyjson.com/image.png',
  images: ['https://dummyjson.com/image.png'],
);

void main() {
  test('maps the API response to a domain page', () async {
    final api = FakeProductsApi(
      response: const ProductsResponse(
        products: [productDto],
        total: 1,
        skip: 0,
        limit: 20,
      ),
    );
    final repository = ProductsRepositoryImpl(api);

    final page = await repository.getProducts(query: const ProductQuery(), limit: 20, skip: 0);

    expect(page.products, hasLength(1));
    expect(page.products.first.id, 1);
    expect(page.total, 1);
    expect(page.limit, 20);
  });

  test('rethrows an AppException from the API', () async {
    final api = FakeProductsApi(
      error: const AppException(AppErrorType.server, 'Error de servidor.'),
    );
    final repository = ProductsRepositoryImpl(api);

    await expectLater(
      repository.getProducts(query: const ProductQuery(), limit: 20, skip: 0),
      throwsA(isA<AppException>()),
    );
  });

  test('maps categories from the API', () async {
    final api = FakeProductsApi(
      categories: [const CategoryDto(slug: 'beauty', name: 'Beauty')],
    );
    final repository = ProductsRepositoryImpl(api);

    final categories = await repository.getCategories();

    expect(categories, hasLength(1));
    expect(categories.first.slug, 'beauty');
    expect(categories.first.name, 'Beauty');
  });

  test('maps the product detail response', () async {
    final api = FakeProductsApi(product: productDto);
    final repository = ProductsRepositoryImpl(api);

    final product = await repository.getProductById(1);

    expect(product.id, 1);
    expect(product.title, 'iPhone 9');
  });

  test('getProductById rethrows a 404 AppException', () async {
    final api = FakeProductsApi(
      productError: const AppException(
        AppErrorType.notFound,
        'Producto no encontrado.',
      ),
    );
    final repository = ProductsRepositoryImpl(api);

    await expectLater(
      repository.getProductById(999),
      throwsA(
        isA<AppException>()
            .having((e) => e.type, 'type', AppErrorType.notFound)
            .having((e) => e.message, 'message', 'Producto no encontrado.'),
      ),
    );
  });

  test('deleteProduct succeeds', () async {
    final repository = ProductsRepositoryImpl(FakeProductsApi());

    await expectLater(repository.deleteProduct(1), completes);
  });

  test('deleteProduct rethrows an AppException', () async {
    final repository = ProductsRepositoryImpl(
      FakeProductsApi(
        productError: const AppException(
          AppErrorType.server,
          'Ocurrió un error en el servidor.',
        ),
      ),
    );

    await expectLater(
      repository.deleteProduct(1),
      throwsA(
        isA<AppException>()
            .having((e) => e.type, 'type', AppErrorType.server),
      ),
    );
  });
}
