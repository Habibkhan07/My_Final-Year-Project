// lib/features/customer/search/domain/entities/search_result_entity.dart

class SearchResultEntity {
  final int id;
  final String name;
  final String categoryName;
  final String? categoryIconUrl;
  final String basePrice;
  final bool isFixedPrice;

  const SearchResultEntity({
    required this.id,
    required this.name,
    required this.categoryName,
    this.categoryIconUrl,
    required this.basePrice,
    required this.isFixedPrice,
  });
}
