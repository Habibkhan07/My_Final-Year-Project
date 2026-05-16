import 'package:freezed_annotation/freezed_annotation.dart';

part 'available_sub_service_entity.freezed.dart';
part 'available_sub_service_entity.g.dart';

/// Sub-service the technician can pick from on the "Add a Skill" screen.
///
/// Fed by the existing `GET /api/technicians/onboarding/metadata/`
/// endpoint, which already returns the full service tree. The screen
/// filters out sub-services the tech already has via a client-side
/// diff against the current `TechnicianSkillEntity` list, so the picker
/// never offers a duplicate (the backend would still reject it with
/// `duplicate_skill`, but the UI shouldn't put the user in that path).
@freezed
abstract class AvailableServiceEntity with _$AvailableServiceEntity {
  const factory AvailableServiceEntity({
    required int id,
    required String name,
    required String? iconName,
    required List<AvailableSubServiceEntity> subServices,
  }) = _AvailableServiceEntity;

  factory AvailableServiceEntity.fromJson(Map<String, dynamic> json) =>
      _$AvailableServiceEntityFromJson(json);
}

@freezed
abstract class AvailableSubServiceEntity with _$AvailableSubServiceEntity {
  const factory AvailableSubServiceEntity({
    required int id,
    required String name,
    required String? iconName,
    @Default(false) bool isFixedPrice,
  }) = _AvailableSubServiceEntity;

  factory AvailableSubServiceEntity.fromJson(Map<String, dynamic> json) =>
      _$AvailableSubServiceEntityFromJson(json);
}
