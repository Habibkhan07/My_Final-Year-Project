// Domain entity for a single tech_gps stream frame received over the
// realtime socket. Orchestrator-feature-specific even though the
// transport (WsFrameDispatcher) is generic — per CLAUDE.md "payload
// model lives with the consumer."
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tech_gps_frame.freezed.dart';

/// One GPS frame from the assigned technician.
///
/// Emitted by `TechnicianLocationStreamNotifier` whenever the WS layer
/// dispatches a `tech_gps` stream frame whose payload `booking_id`
/// matches this notifier's family argument.
///
/// **Why `frameArrivedAt` is client-side.** The backend's stream
/// envelope carries a top-level `timestamp`, but `WsFrameDispatcher`
/// passes only `frame['payload']` to handlers — the envelope timestamp
/// is dropped before reaching the consumer. The mapper stamps
/// arrival-time at the moment the handler fires; the 60-second
/// staleness threshold is anchored on this. Threading server time
/// through the dispatcher is a separate refactor (and a 60s soft
/// threshold tolerates the 1–2s WS round-trip just fine).
@freezed
abstract class TechGpsFrame with _$TechGpsFrame {
  const factory TechGpsFrame({
    required int bookingId,
    required double latitude,
    required double longitude,

    /// GPS reported accuracy in metres. Many handsets emit `null` for
    /// indoor or low-quality fixes — accept and ignore.
    double? accuracyMeters,

    /// GPS heading in degrees clockwise from north (0..360). Many
    /// handsets emit `null` when stationary (0 m/s). The marker
    /// rotation defaults to north when heading is null.
    double? heading,

    /// Wall-clock instant when the frame arrived at this client. Used
    /// for the 60-second "tech offline" staleness banner.
    required DateTime frameArrivedAt,
  }) = _TechGpsFrame;
}
