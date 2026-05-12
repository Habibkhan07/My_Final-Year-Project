// Wire model for the tech-side quote builder dropdown.
//
// Source: `GET /api/technicians/me/quotable-sub-services/?service_id=N`
// (`backend/technicians/api/quote_catalog/views.py`).
//
// Prices arrive as wire-strings (Decimals → str on the Django side).
// `maxPrice` is null when `isFixedPrice` is true — the frontend uses
// that null as the signal to lock the price field and substitute
// `basePrice` for `priced_at` on submit.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quotable_sub_service_model.freezed.dart';
part 'quotable_sub_service_model.g.dart';

@freezed
abstract class QuotableSubServiceModel with _$QuotableSubServiceModel {
  const factory QuotableSubServiceModel({
    required int id,
    required String name,
    @JsonKey(name: 'base_price') required String basePrice,
    @JsonKey(name: 'max_price') String? maxPrice,
    @JsonKey(name: 'is_fixed_price') required bool isFixedPrice,
  }) = _QuotableSubServiceModel;

  factory QuotableSubServiceModel.fromJson(Map<String, dynamic> json) =>
      _$QuotableSubServiceModelFromJson(json);
}
