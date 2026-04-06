import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_entity.freezed.dart';

/// [ServiceEntity] represents a broad category of services (e.g., Plumbing).
/// MAPPED FROM: ServiceModel
@freezed
abstract class ServiceEntity with _$ServiceEntity {
  const factory ServiceEntity({
    required int id,
    required String name,
    required List<SubServiceEntity> subServices,
  }) = _ServiceEntity;
}

/// [SubServiceEntity] represents a specific gig/skill metadata.
/// MAPPED FROM: SubServiceModel
@freezed
abstract class SubServiceEntity with _$SubServiceEntity {
  const factory SubServiceEntity({
    required int id,
    required String name,
    required String basePrice,
    required String? maxPrice,
    String? iconName,
  }) = _SubServiceEntity;
}
