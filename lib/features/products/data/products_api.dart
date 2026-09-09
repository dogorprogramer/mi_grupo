import 'package:dio/dio.dart';

import '../../../core/network/error_mapper.dart';
import 'models/products_response.dart';

class ProductsApi {
  ProductsApi(this._dio);

  final Dio _dio;

  Future<ProductsResponse> getProducts({required int limit, required int skip}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {'limit': limit, 'skip': skip},
      );
      return ProductsResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
