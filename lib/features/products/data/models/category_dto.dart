import '../../domain/category.dart';

class CategoryDto {
  const CategoryDto({required this.slug, required this.name, this.url});

  final String slug;
  final String name;
  final String? url;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      slug: json['slug'] as String,
      name: json['name'] as String,
      url: json['url'] as String?,
    );
  }

  Category toDomain() {
    return Category(slug: slug, name: name, url: url);
  }
}
