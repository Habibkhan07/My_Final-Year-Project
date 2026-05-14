// Wire model for the `state_summary` block embedded in every turn /
// start / detail response.
//
// Source of truth: `backend/chatbot/views.py::_state_summary`.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'state_summary_model.freezed.dart';
part 'state_summary_model.g.dart';

@freezed
abstract class StateSummaryModel with _$StateSummaryModel {
  const factory StateSummaryModel({
    @Default('') String phase,
    @JsonKey(name: 'captured_fields') @Default({})
    Map<String, dynamic> capturedFields,
    @JsonKey(name: 'attachments_count') @Default(0) int attachmentsCount,
  }) = _StateSummaryModel;

  factory StateSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$StateSummaryModelFromJson(json);
}
