// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotable_sub_service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuotableSubServiceModel _$QuotableSubServiceModelFromJson(
  Map<String, dynamic> json,
) => _QuotableSubServiceModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  basePrice: json['base_price'] as String,
  maxPrice: json['max_price'] as String?,
  isFixedPrice: json['is_fixed_price'] as bool,
);

Map<String, dynamic> _$QuotableSubServiceModelToJson(
  _QuotableSubServiceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'base_price': instance.basePrice,
  'max_price': instance.maxPrice,
  'is_fixed_price': instance.isFixedPrice,
};
