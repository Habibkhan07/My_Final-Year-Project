// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceModel _$ServiceModelFromJson(Map<String, dynamic> json) =>
    _ServiceModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      subServices: (json['sub_services'] as List<dynamic>)
          .map((e) => SubServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServiceModelToJson(_ServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sub_services': instance.subServices,
    };

_SubServiceModel _$SubServiceModelFromJson(Map<String, dynamic> json) =>
    _SubServiceModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      basePrice: json['base_price'] as String,
      maxPrice: json['max_price'] as String?,
      iconName: json['icon_name'] as String?,
    );

Map<String, dynamic> _$SubServiceModelToJson(_SubServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'base_price': instance.basePrice,
      'max_price': instance.maxPrice,
      'icon_name': instance.iconName,
    };
