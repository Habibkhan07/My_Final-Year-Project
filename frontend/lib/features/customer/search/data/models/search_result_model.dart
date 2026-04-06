import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/search_result_entity.dart';

part 'search_result_model.freezed.dart';
part 'search_result_model.g.dart';

@freezed
abstract class SearchResultModel with _$SearchResultModel {
  const SearchResultModel._();

  const factory SearchResultModel({
    required int id,
    required String name,
    @JsonKey(name: 'category_name') required String categoryName,
    @JsonKey(name: 'category_icon_url') String? categoryIconUrl,
    @JsonKey(name: 'base_price') required String basePrice,
    @JsonKey(name: 'is_fixed_price') required bool isFixedPrice,
  }) = _SearchResultModel;

  factory SearchResultModel.fromJson(Map<String, dynamic> json) => _$SearchResultModelFromJson(json);

  SearchResultEntity toEntity() => SearchResultEntity(
    id: id,
    name: name,
    categoryName: categoryName,
    categoryIconUrl: categoryIconUrl,
    basePrice: basePrice,
    isFixedPrice: isFixedPrice,
  );
}
