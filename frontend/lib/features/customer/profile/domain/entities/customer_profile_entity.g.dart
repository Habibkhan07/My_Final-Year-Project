// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomerProfileEntity _$CustomerProfileEntityFromJson(
  Map<String, dynamic> json,
) => _CustomerProfileEntity(
  id: (json['id'] as num).toInt(),
  phone: json['phone'] as String,
  isTechnician: json['isTechnician'] as bool? ?? false,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
);

Map<String, dynamic> _$CustomerProfileEntityToJson(
  _CustomerProfileEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'isTechnician': instance.isTechnician,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
};
