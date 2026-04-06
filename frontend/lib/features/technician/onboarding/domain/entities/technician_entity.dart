import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_entity.freezed.dart';

/// [TechnicianEntity] is the domain entity returned after a successful registration.
/// MAPPED FROM: RegisterTechnicianView response
@freezed
abstract class TechnicianEntity with _$TechnicianEntity {
  const factory TechnicianEntity({
    required int profileId,
    required String status,
    required String fullName,
    required String joinedDate,
    required int experienceYears,
  }) = _TechnicianEntity;
}
