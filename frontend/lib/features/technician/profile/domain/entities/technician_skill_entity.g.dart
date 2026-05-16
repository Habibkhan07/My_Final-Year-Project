// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_skill_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TechnicianSkillEntity _$TechnicianSkillEntityFromJson(
  Map<String, dynamic> json,
) => _TechnicianSkillEntity(
  id: (json['id'] as num).toInt(),
  subService: SubServiceRef.fromJson(
    json['subService'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$TechnicianSkillEntityToJson(
  _TechnicianSkillEntity instance,
) => <String, dynamic>{'id': instance.id, 'subService': instance.subService};

_SubServiceRef _$SubServiceRefFromJson(Map<String, dynamic> json) =>
    _SubServiceRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      iconName: json['iconName'] as String?,
      isFixedPrice: json['isFixedPrice'] as bool? ?? false,
      service: ParentServiceRef.fromJson(
        json['service'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SubServiceRefToJson(_SubServiceRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconName': instance.iconName,
      'isFixedPrice': instance.isFixedPrice,
      'service': instance.service,
    };

_ParentServiceRef _$ParentServiceRefFromJson(Map<String, dynamic> json) =>
    _ParentServiceRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      iconName: json['iconName'] as String?,
    );

Map<String, dynamic> _$ParentServiceRefToJson(_ParentServiceRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconName': instance.iconName,
    };
