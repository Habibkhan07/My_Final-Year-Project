import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_event_model.freezed.dart';
part 'system_event_model.g.dart';

/// JSON contract for real-time system events.
///
/// Fed by two backend sources:
///   - WebSocket frames from Django Channels (live push).
///   - `GET /api/events/sync/` and `GET /api/events/unacknowledged/`.
///
/// [timestamp] is kept as a raw ISO-8601 string here. Parsing to [DateTime]
/// is the mapper's job (wrapped in try/catch), so a malformed timestamp
/// from a single event can never crash the listener loop.
@freezed
abstract class SystemEventModel with _$SystemEventModel {
  const factory SystemEventModel({
    required String id,
    @JsonKey(name: 'rawType') required String rawType,
    @JsonKey(name: 'targetRole') required String targetRole,
    required String timestamp,
    required Map<String, dynamic> payload,
  }) = _SystemEventModel;

  factory SystemEventModel.fromJson(Map<String, dynamic> json) =>
      _$SystemEventModelFromJson(json);
}
