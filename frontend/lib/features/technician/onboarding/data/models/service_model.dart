import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_model.freezed.dart';
part 'service_model.g.dart';

/// [ServiceModel] represents the metadata for onboarding.
/// FEEDS FROM: GET /api/technicians/onboarding/metadata/
@freezed
abstract class ServiceModel with _$ServiceModel {
  const factory ServiceModel({
    required int id,
    required String name,
    @JsonKey(name: 'sub_services') required List<SubServiceModel> subServices,
  }) = _ServiceModel;

  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);
}

/// [SubServiceModel] represents a specific gig/skill metadata.
/// FEEDS FROM: GET /api/technicians/onboarding/metadata/
@freezed
abstract class SubServiceModel with _$SubServiceModel {
  const factory SubServiceModel({
    required int id,
    required String name,
    @JsonKey(name: 'base_price') required String basePrice,
    @JsonKey(name: 'max_price') required String? maxPrice,
    @JsonKey(name: 'icon_name') String? iconName,
  }) = _SubServiceModel;

  factory SubServiceModel.fromJson(Map<String, dynamic> json) =>
      _$SubServiceModelFromJson(json);
}
