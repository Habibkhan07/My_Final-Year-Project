// Wire model for the orchestrator screen's UI block.
// Source of truth: `backend/bookings/selectors/orchestrator_ui.py`.
//
// Faithful to the wire — no domain types, no fallbacks. The mapper
// (`booking_detail_mapper.dart`) coerces tone + style strings to typed
// enums and the cache round-trips through the same JSON shape.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_ui_block_model.freezed.dart';
part 'booking_ui_block_model.g.dart';

@freezed
abstract class BookingUiBlockModel with _$BookingUiBlockModel {
  const factory BookingUiBlockModel({
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'body_text') required String bodyText,
    @JsonKey(name: 'primary_action') BookingUiActionModel? primaryAction,
    @JsonKey(name: 'secondary_actions')
    @Default(<BookingUiActionModel>[])
    List<BookingUiActionModel> secondaryActions,
    @JsonKey(name: 'show_tracking') required bool showTracking,
    @JsonKey(name: 'show_quote_card') required bool showQuoteCard,
    @JsonKey(name: 'show_dispute_button') required bool showDisputeButton,
    required String tone,
  }) = _BookingUiBlockModel;

  factory BookingUiBlockModel.fromJson(Map<String, dynamic> json) =>
      _$BookingUiBlockModelFromJson(json);
}

@freezed
abstract class BookingUiActionModel with _$BookingUiActionModel {
  const factory BookingUiActionModel({
    required String label,
    required String endpoint,
    required String method,
    String? style,
  }) = _BookingUiActionModel;

  factory BookingUiActionModel.fromJson(Map<String, dynamic> json) =>
      _$BookingUiActionModelFromJson(json);
}
