import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovery_entities.freezed.dart';

@freezed
abstract class DiscoveryTechnicianEntity with _$DiscoveryTechnicianEntity {
  const factory DiscoveryTechnicianEntity({
    required int id,
    required String fullName,
    required String primaryCategory,
    required String city,
    required String? profilePicture,
    required double ratingAverage,
    required int reviewCount,
    required double? distanceKm,
    required double? bayesianScore,
    required bool isActive,

    // Unified Money Corner (Dumb UI)
    required String uiRatingText,
    required String primaryPrice,
    required String priceContext,
    required String? promoTag,
    required String? uiSubtitleText,
  }) = _DiscoveryTechnicianEntity;
}

@freezed
abstract class DiscoveryResultEntity with _$DiscoveryResultEntity {
  const factory DiscoveryResultEntity({
    required int count,
    required String? next,
    required String? previous,
    required String? uiPromoBannerText,
    required List<DiscoveryTechnicianEntity> results,
  }) = _DiscoveryResultEntity;
}
