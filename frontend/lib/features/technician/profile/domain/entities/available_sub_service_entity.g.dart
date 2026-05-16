// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_sub_service_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvailableServiceEntity _$AvailableServiceEntityFromJson(
  Map<String, dynamic> json,
) => _AvailableServiceEntity(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  iconName: json['iconName'] as String?,
  subServices: (json['subServices'] as List<dynamic>)
      .map((e) => AvailableSubServiceEntity.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AvailableServiceEntityToJson(
  _AvailableServiceEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'iconName': instance.iconName,
  'subServices': instance.subServices,
};

_AvailableSubServiceEntity _$AvailableSubServiceEntityFromJson(
  Map<String, dynamic> json,
) => _AvailableSubServiceEntity(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  iconName: json['iconName'] as String?,
  isFixedPrice: json['isFixedPrice'] as bool? ?? false,
);

Map<String, dynamic> _$AvailableSubServiceEntityToJson(
  _AvailableSubServiceEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'iconName': instance.iconName,
  'isFixedPrice': instance.isFixedPrice,
};
