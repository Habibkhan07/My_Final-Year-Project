// Wire model for the `ui_form_schema` block carried on PAYOUT-phase
// turn responses.
//
// Source of truth: `backend/chatbot/personas/dispute/schemas.py`
// `BANK_FORM_SCHEMA`.
//
// Note the wire field is `key` (not `name`); the mapper translates.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_schema_model.freezed.dart';
part 'form_schema_model.g.dart';

@freezed
abstract class FormFieldModel with _$FormFieldModel {
  const factory FormFieldModel({
    required String key,
    required String label,
    required String type,
    @Default(false) bool required,
    @JsonKey(name: 'max_length') int? maxLength,
    String? pattern,
    String? hint,
  }) = _FormFieldModel;

  factory FormFieldModel.fromJson(Map<String, dynamic> json) =>
      _$FormFieldModelFromJson(json);
}

@freezed
abstract class FormSchemaModel with _$FormSchemaModel {
  const factory FormSchemaModel({
    required List<FormFieldModel> fields,
  }) = _FormSchemaModel;

  factory FormSchemaModel.fromJson(Map<String, dynamic> json) =>
      _$FormSchemaModelFromJson(json);
}
