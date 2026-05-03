// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserEntity _$UserEntityFromJson(Map<String, dynamic> json) => _UserEntity(
  phone: json['phone'] as String,
  id: (json['id'] as num?)?.toInt(),
  token: json['token'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  isTechnician: json['isTechnician'] as bool? ?? false,
  nameRequired: json['nameRequired'] as bool? ?? false,
);

Map<String, dynamic> _$UserEntityToJson(_UserEntity instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'id': instance.id,
      'token': instance.token,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'isTechnician': instance.isTechnician,
      'nameRequired': instance.nameRequired,
    };
