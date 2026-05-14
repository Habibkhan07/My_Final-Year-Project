// Wire model for `POST /api/chat/conversations/<id>/close/` response.
// Source of truth: `backend/chatbot/views.py::close_view`.
//
// Idempotent endpoint: a second call on an already-closed conversation
// returns the same shape with the original `closed_at` + `output_refs`
// from the first close. The repository surfaces this as "fetch detail
// + treat as terminal" rather than throwing.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'close_response_model.freezed.dart';
part 'close_response_model.g.dart';

@freezed
abstract class CloseResponseModel with _$CloseResponseModel {
  const factory CloseResponseModel({
    @JsonKey(name: 'closed_at') String? closedAt,
    @JsonKey(name: 'output_refs') @Default({})
    Map<String, dynamic> outputRefs,
  }) = _CloseResponseModel;

  factory CloseResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CloseResponseModelFromJson(json);
}
