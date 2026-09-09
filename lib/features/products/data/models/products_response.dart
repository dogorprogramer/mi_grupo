import '../../domain/products_page.dart';
import 'product_dto.dart';

class ProductsResponse {
  const ProductsResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<ProductDto> products;
  final int total;
  final int skip;
  final int limit;

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      products: (json['products'] as List<dynamic>)
          .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      skip: json['skip'] as int,
      limit: json['limit'] as int,
    );
  }

  ProductsPage toDomain() {
    return ProductsPage(
      products: products.map((e) => e.toDomain()).toList(),
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}
