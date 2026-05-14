// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_schema_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FormFieldModel _$FormFieldModelFromJson(Map<String, dynamic> json) =>
    _FormFieldModel(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      required: json['required'] as bool? ?? false,
      maxLength: (json['max_length'] as num?)?.toInt(),
      pattern: json['pattern'] as String?,
      hint: json['hint'] as String?,
    );

Map<String, dynamic> _$FormFieldModelToJson(_FormFieldModel instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'type': instance.type,
      'required': instance.required,
      'max_length': instance.maxLength,
      'pattern': instance.pattern,
      'hint': instance.hint,
    };

_FormSchemaModel _$FormSchemaModelFromJson(Map<String, dynamic> json) =>
    _FormSchemaModel(
      fields: (json['fields'] as List<dynamic>)
          .map((e) => FormFieldModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FormSchemaModelToJson(_FormSchemaModel instance) =>
    <String, dynamic>{'fields': instance.fields};
