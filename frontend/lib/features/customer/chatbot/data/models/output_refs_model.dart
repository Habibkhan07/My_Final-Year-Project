// Wire model for the `output_refs` block emitted once a conversation
// closes. Today the dispute persona writes only `support_ticket_id`;
// other personas will add their own keys.
//
// Source of truth:
// `backend/chatbot/personas/dispute/outputs.py::finalize_dispute`.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'output_refs_model.freezed.dart';
part 'output_refs_model.g.dart';

@freezed
abstract class OutputRefsModel with _$OutputRefsModel {
  const factory OutputRefsModel({
    @JsonKey(name: 'support_ticket_id') int? supportTicketId,
  }) = _OutputRefsModel;

  factory OutputRefsModel.fromJson(Map<String, dynamic> json) =>
      _$OutputRefsModelFromJson(json);
}
