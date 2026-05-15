// Wire model for a single scheduled-job row.
// Source of truth: `backend/technicians/api/SCHEDULED_JOBS_API.md` §1.4.
//
// Faithful to the wire — no domain types, no defaults applied here. The
// mapper translates wire strings to typed domain values + applies
// fallbacks for nullable fields. Keeping this model dumb means the local
// cache round-trips through the same JSON shape the network returns.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheduled_job_model.freezed.dart';
part 'scheduled_job_model.g.dart';

@freezed
abstract class ScheduledJobModel with _$ScheduledJobModel {
  const factory ScheduledJobModel({
    required int id,
    required String status,
    required ScheduledJobServiceModel service,
    required ScheduledJobCustomerModel customer,
    @JsonKey(name: 'address_label') required String? addressLabel,
    @JsonKey(name: 'scheduled_start') required String scheduledStart,
    @JsonKey(name: 'scheduled_end') required String scheduledEnd,
    @JsonKey(name: 'created_at') required String createdAt,
    required PayoutBlockModel payout,
    required ScheduledJobUiModel ui,
  }) = _ScheduledJobModel;

  factory ScheduledJobModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduledJobModelFromJson(json);
}

@freezed
abstract class ScheduledJobServiceModel with _$ScheduledJobServiceModel {
  const factory ScheduledJobServiceModel({
    required String name,
    @JsonKey(name: 'icon_name') required String iconName,
  }) = _ScheduledJobServiceModel;

  factory ScheduledJobServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduledJobServiceModelFromJson(json);
}

@freezed
abstract class ScheduledJobCustomerModel with _$ScheduledJobCustomerModel {
  const factory ScheduledJobCustomerModel({
    required int id,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'profile_picture_url') required String? profilePictureUrl,
  }) = _ScheduledJobCustomerModel;

  factory ScheduledJobCustomerModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduledJobCustomerModelFromJson(json);
}

@freezed
abstract class PayoutBlockModel with _$PayoutBlockModel {
  const factory PayoutBlockModel({
    required int amount,
    required String context,
    @JsonKey(name: 'ui_label') required String uiLabel,
  }) = _PayoutBlockModel;

  factory PayoutBlockModel.fromJson(Map<String, dynamic> json) =>
      _$PayoutBlockModelFromJson(json);
}

@freezed
abstract class ScheduledJobUiModel with _$ScheduledJobUiModel {
  const factory ScheduledJobUiModel({
    @JsonKey(name: 'badge_text') required String badgeText,
    @JsonKey(name: 'badge_tone') required String badgeTone,
    required String headline,
  }) = _ScheduledJobUiModel;

  factory ScheduledJobUiModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduledJobUiModelFromJson(json);
}
