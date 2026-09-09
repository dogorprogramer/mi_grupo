import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/features/products/data/models/category_dto.dart';
import 'package:mi_grupo/features/products/data/models/product_dto.dart';
import 'package:mi_grupo/features/products/data/models/products_response.dart';

void main() {
  group('CategoryDto.fromJson', () {
    test('parses a real DummyJSON category object', () {
      final json = {
        'slug': 'beauty',
        'name': 'Beauty',
        'url': 'https://dummyjson.com/products/category/beauty',
      };

      final category = CategoryDto.fromJson(json).toDomain();

      expect(category.slug, 'beauty');
      expect(category.name, 'Beauty');
      expect(category.url, 'https://dummyjson.com/products/category/beauty');
    });
  });

  group('ProductDto.fromJson', () {
    test('parses a real DummyJSON product', () {
      final json = {
        'id': 1,
        'title': 'iPhone 9',
        'description': 'An apple mobile which is nothing like apple',
        'category': 'smartphones',
        'price': 549,
        'rating': 4.69,
        'stock': 94,
        'brand': 'Apple',
        'thumbnail': 'https://dummyjson.com/image.png',
        'images': [
          'https://dummyjson.com/image.png',
          'https://dummyjson.com/image2.png',
        ],
      };

      final product = ProductDto.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'iPhone 9');
      expect(product.category, 'smartphones');
      expect(product.price, 549.0);
      expect(product.rating, 4.69);
      expect(product.stock, 94);
      expect(product.brand, 'Apple');
      expect(product.thumbnail, 'https://dummyjson.com/image.png');
      expect(product.images, hasLength(2));
    });
  });

  group('ProductsResponse.fromJson', () {
    test('parses a real DummyJSON products page', () {
      final json = {
        'products': [
          {
            'id': 1,
            'title': 'iPhone 9',
            'description': 'desc',
            'category': 'smartphones',
            'price': 549,
            'rating': 4.69,
            'stock': 94,
            'brand': 'Apple',
            'thumbnail': 'https://dummyjson.com/image.png',
            'images': ['https://dummyjson.com/image.png'],
          },
        ],
        'total': 194,
        'skip': 0,
        'limit': 20,
      };

      final response = ProductsResponse.fromJson(json);

      expect(response.total, 194);
      expect(response.skip, 0);
      expect(response.limit, 20);
      expect(response.products, hasLength(1));

      final page = response.toDomain();
      expect(page.products, hasLength(1));
      expect(page.products.first.id, 1);
    });
  });
}
