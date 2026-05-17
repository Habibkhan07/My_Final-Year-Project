import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_skill_entity.freezed.dart';
part 'technician_skill_entity.g.dart';

/// One row in the technician's skill list.
///
/// Fed by `GET /api/technicians/me/skills/`. The same shape is returned
/// by `POST /api/technicians/me/skills/`, so the FE notifier can merge
/// the create response directly into the cached list without a second
/// round-trip.
///
/// Bridge row is pure membership after migrations 0013/0014 (2026-05-17
/// onboarding refactor) — no per-skill pricing or experience to surface.
/// Labor figures come from `catalog.SubService.base_price`.
@freezed
abstract class TechnicianSkillEntity with _$TechnicianSkillEntity {
  const factory TechnicianSkillEntity({
    /// Bridge row PK. Stable within the row's lifetime, but the delete
    /// endpoint keys by `subService.id` (the catalog row), not this id.
    required int id,
    required SubServiceRef subService,
  }) = _TechnicianSkillEntity;

  factory TechnicianSkillEntity.fromJson(Map<String, dynamic> json) =>
      _$TechnicianSkillEntityFromJson(json);
}

/// Nested catalog reference inside a skill row.
///
/// Carries `iconName` for `IconAssets.path()` — the SVG ships with the
/// Flutter app, NOT the backend. `isFixedPrice` is here for future-
/// proofing (the skills screen may want to badge fixed-price skills
/// differently); currently unused on the read side.
@freezed
abstract class SubServiceRef with _$SubServiceRef {
  const factory SubServiceRef({
    required int id,
    required String name,
    required String? iconName,
    @Default(false) bool isFixedPrice,
    required ParentServiceRef service,
  }) = _SubServiceRef;

  factory SubServiceRef.fromJson(Map<String, dynamic> json) =>
      _$SubServiceRefFromJson(json);
}

/// Parent-service nested inside the sub-service reference. Drives the
/// service-grouped section headers on the My Skills screen.
@freezed
abstract class ParentServiceRef with _$ParentServiceRef {
  const factory ParentServiceRef({
    required int id,
    required String name,
    required String? iconName,
  }) = _ParentServiceRef;

  factory ParentServiceRef.fromJson(Map<String, dynamic> json) =>
      _$ParentServiceRefFromJson(json);
}
