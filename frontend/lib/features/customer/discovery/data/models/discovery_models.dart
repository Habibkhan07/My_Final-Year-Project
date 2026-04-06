import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/discovery_entities.dart';

part 'discovery_models.freezed.dart';
part 'discovery_models.g.dart';

@freezed
abstract class TechnicianModel with _$TechnicianModel {
  const factory TechnicianModel({
    required int id,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'primary_category') required String primaryCategory,
    required String city,
    @JsonKey(name: 'profile_picture') required String? profilePicture,
    @JsonKey(name: 'rating_average') required double ratingAverage,
    @JsonKey(name: 'review_count') required int reviewCount,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'bayesian_score') double? bayesianScore,
    @JsonKey(name: 'is_active') required bool isActive,

    // Dumb UI Fields
    @JsonKey(name: 'ui_rating_text') required String uiRatingText,
    @JsonKey(name: 'primary_price') required String primaryPrice,
    @JsonKey(name: 'price_context') required String priceContext,
    @JsonKey(name: 'promo_tag') String? promoTag,
    @JsonKey(name: 'ui_subtitle_text') String? uiSubtitleText,
  }) = _TechnicianModel;

  factory TechnicianModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianModelFromJson(json);

  const TechnicianModel._();

  DiscoveryTechnicianEntity toEntity() => DiscoveryTechnicianEntity(
        id: id,
        fullName: fullName,
        primaryCategory: primaryCategory,
        city: city,
        profilePicture: profilePicture,
        ratingAverage: ratingAverage,
        reviewCount: reviewCount,
        distanceKm: distanceKm,
        bayesianScore: bayesianScore,
        isActive: isActive,
        uiRatingText: uiRatingText,
        primaryPrice: primaryPrice,
        priceContext: priceContext,
        promoTag: promoTag,
        uiSubtitleText: uiSubtitleText,
      );
}

@freezed
abstract class DiscoveryResultModel with _$DiscoveryResultModel {
  const factory DiscoveryResultModel({
    required int count,
    required String? next,
    required String? previous,
    @JsonKey(name: 'ui_promo_banner_text') required String? uiPromoBannerText,
    required List<TechnicianModel> results,
  }) = _DiscoveryResultModel;

  factory DiscoveryResultModel.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryResultModelFromJson(json);

  const DiscoveryResultModel._();

  DiscoveryResultEntity toEntity() => DiscoveryResultEntity(
        count: count,
        next: next,
        previous: previous,
        uiPromoBannerText: uiPromoBannerText,
        results: results.map((e) => e.toEntity()).toList(),
      );
}
