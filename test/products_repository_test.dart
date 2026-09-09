import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/core/errors/app_exception.dart';
import 'package:mi_grupo/features/products/data/models/product_dto.dart';
import 'package:mi_grupo/features/products/data/models/products_response.dart';
import 'package:mi_grupo/features/products/data/products_api.dart';
import 'package:mi_grupo/features/products/data/products_repository_impl.dart';

class FakeProductsApi extends ProductsApi {
  FakeProductsApi({this.response, this.error}) : super(Dio());

  final ProductsResponse? response;
  final Object? error;

  @override
  Future<ProductsResponse> getProducts({required int limit, required int skip}) async {
    if (error != null) throw error!;
    return response!;
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

    final page = await repository.getProducts(limit: 20, skip: 0);

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
      repository.getProducts(limit: 20, skip: 0),
      throwsA(isA<AppException>()),
    );
  });
}
