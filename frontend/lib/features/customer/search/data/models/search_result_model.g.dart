// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchResultModel _$SearchResultModelFromJson(Map<String, dynamic> json) =>
    _SearchResultModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      categoryName: json['category_name'] as String,
      categoryIconUrl: json['category_icon_url'] as String?,
      basePrice: json['base_price'] as String,
      isFixedPrice: json['is_fixed_price'] as bool,
    );

Map<String, dynamic> _$SearchResultModelToJson(_SearchResultModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category_name': instance.categoryName,
      'category_icon_url': instance.categoryIconUrl,
      'base_price': instance.basePrice,
      'is_fixed_price': instance.isFixedPrice,
    };
