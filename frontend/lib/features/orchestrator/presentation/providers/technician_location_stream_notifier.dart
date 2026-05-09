// Per-stream consumer notifier for the `tech_gps` realtime stream.
// First stream consumer in the codebase — the pattern documented here
// is what future stream features (live wallet balance, AI chatbot
// tokens, typing indicators) will mirror.
//
// Wire contract (verified against backend):
//   • Backend publishes `{kind: "stream", streamType: "tech_gps",
//     timestamp, payload: {lat, lng, accuracy_meters, heading,
//     booking_id}}` to the `tracking_job_<id>` channel-layer group.
//   • `WsFrameDispatcher._routeStream` invokes the registered handler
//     with `frame['payload']` only — the envelope timestamp is dropped.
//   • This notifier is single-handler-per-streamType (audit P0-07).
//     Running two orchestrator screens for two different bookings
//     simultaneously would race; the second register() overwrites the
//     first's handler. v1 acceptable; flag #ws-stream-multi-handler-deferred.
//
// SECURITY: read-only realtime stream. Frames are scoped server-side
// to the booking-participant subgroup; this client only acts on frames
// whose payload `booking_id` matches the screen's family argument.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/realtime/presentation/providers/dependency_injection.dart';
import '../../data/mappers/tech_gps_frame_mapper.dart';
import '../../data/models/tech_gps_frame_model.dart';
import '../../domain/entities/tech_gps_frame.dart';

part 'technician_location_stream_notifier.g.dart';

/// Holds the latest [TechGpsFrame] received for [jobId], or `null`
/// before the first frame arrives.
///
/// keepAlive: false — scoped to the orchestrator screen lifetime.
/// `EnRouteBodyStub` / `ArrivedBodyStub` `ref.watch` this provider;
/// popping the screen disposes the provider, which unregisters the
/// dispatcher handler.
///
/// **Why `Future.microtask` + `ref.mounted` (audit P1-05).** When the
/// dispatcher invokes the registered handler, we MUST NOT mutate
/// `state` synchronously inside `build()`. A frame buffered in the WS
/// channel before `build()` returns would corrupt initial state.
/// Deferring via `Future.microtask` guarantees the mutation lands on
/// the next microtask after `build()` returned. The `ref.mounted`
/// guard prevents post-disposal writes (the screen popped while a
/// frame was in flight).
@Riverpod(keepAlive: false)
class TechnicianLocationStreamNotifier
    extends _$TechnicianLocationStreamNotifier {
  @override
  TechGpsFrame? build(int jobId) {
    final dispatcher = ref.read(wsFrameDispatcherProvider);

    void handler(Map<String, dynamic> payload) {
      final TechGpsFrameModel model;
      try {
        model = TechGpsFrameModel.fromJson(payload);
      } catch (_) {
        // Malformed frame — drop. The wire contract is locked
        // server-side, so this only fires on real version skew.
        return;
      }
      // Defensive — late frames after unsubscribe could arrive for a
      // booking we already left. Drop anything that's not us.
      if (model.bookingId != jobId) return;

      final frame = TechGpsFrameMapper.toDomain(model);
      // Audit P1-05: defer past build()'s return + guard against
      // post-disposal writes.
      Future.microtask(() {
        if (!ref.mounted) return;
        state = frame;
      });
    }

    dispatcher.register('tech_gps', handler);
    ref.onDispose(() {
      // Audit C5 (R-3): pass our handler reference so the dispatcher
      // only removes if its currently-registered handler is identical
      // to ours. If a successor notifier (e.g. a new orchestrator
      // screen mounted before our dispose ran) has already replaced
      // the registration, the identity check makes unregister a no-op
      // and the successor's handler stays live.
      //
      // Audit P0-07 / flag `ws-stream-multi-handler-deferred`: the
      // dispatcher remains single-handler-per-type for now; the
      // multi-handler refactor will key a list-remove on the same
      // identity comparison.
      dispatcher.unregister('tech_gps', handler);
    });

    return null;
  }
}
