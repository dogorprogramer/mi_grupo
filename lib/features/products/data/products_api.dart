import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/error_mapper.dart';
import '../domain/product_query.dart';
import 'models/category_dto.dart';
import 'models/product_dto.dart';
import 'models/products_response.dart';

class ProductsApi {
  ProductsApi(this._dio);

  final Dio _dio;

  Future<ProductsResponse> fetchProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) async {
    try {
      final response = await _requestProducts(query: query, limit: limit, skip: skip);
      return ProductsResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<ProductDto> getProductById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/$id');
      return ProductDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDetailError(e);
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/products/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<CategoryDto>> getCategories() async {
    try {
      final response = await _dio.get<List<dynamic>>('/products/categories');
      return (response.data ?? [])
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  AppException _mapDetailError(DioException e) {
    if (e.type == DioExceptionType.badResponse && e.response?.statusCode == 404) {
      return const AppException(
        AppErrorType.notFound,
        'Producto no encontrado.',
      );
    }
    return mapDioException(e);
  }

  Future<Response<Map<String, dynamic>>> _requestProducts({
    required ProductQuery query,
    required int limit,
    required int skip,
  }) {
    final search = query.search;
    final category = query.category;
    if (search != null && search.isNotEmpty) {
      return _dio.get<Map<String, dynamic>>(
        '/products/search',
        queryParameters: {'q': search, 'limit': limit, 'skip': skip},
      );
    }
    if (category != null && category.isNotEmpty) {
      return _dio.get<Map<String, dynamic>>(
        '/products/category/$category',
        queryParameters: {'limit': limit, 'skip': skip},
      );
    }
    return _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {'limit': limit, 'skip': skip},
    );
  }
}
