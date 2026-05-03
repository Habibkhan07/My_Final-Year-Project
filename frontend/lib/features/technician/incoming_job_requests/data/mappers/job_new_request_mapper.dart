// Translates the generic [SystemEventEntity] envelope into the typed
// [JobNewRequest] domain entity. This is the single boundary where wire
// strings become typed values (e.g. integer-string `payout` → int) and where
// §2.5 backwards-compat defaults are applied (null `bookingType` → laborGig).
//
// The mapper logs and returns null on malformed payloads rather than throwing —
// the dispatcher's policy is "drop and log" (see `WsFrameDispatcher._routeEvent`),
// and matching that policy here keeps the queue notifier's filter loop simple.
import 'dart:developer';

import '../../../../../core/realtime/domain/entities/system_event_entity.dart';
import '../../domain/entities/booking_type.dart';
import '../../domain/entities/job_new_request.dart';
import '../models/job_new_request_payload_model.dart';

class JobNewRequestMapper {
  JobNewRequestMapper._();

  static const _logName =
      'features.technician.incoming_job_requests.mapper';

  /// Wire enum strings → typed [BookingType]. Inputs are case-sensitive per
  /// the backend contract (`INSPECTION` / `FIXED_GIG` / `LABOR_GIG`).
  static const _bookingTypeLookup = <String, BookingType>{
    'INSPECTION': BookingType.inspection,
    'FIXED_GIG': BookingType.fixedGig,
    'LABOR_GIG': BookingType.laborGig,
  };

  /// Returns null when the payload is malformed (logged at severe level).
  /// Returns null when [event.eventType] is not `jobNewRequest` — caller's
  /// filter should already prevent this, but the guard keeps the mapper
  /// safe to call with any envelope.
  ///
  /// Returns null when the offer's SLA has already elapsed by the time the
  /// envelope reaches us — see "Stale FCM tap" below.
  ///
  /// **Stale FCM tap (flag #19 defence-in-depth).** A `job_new_request`
  /// notification can sit in the OS tray for longer than the SLA window —
  /// the technician was in a meeting, on a metro without signal, or simply
  /// not looking at their phone. Tapping a stale tray banner cold-launches
  /// the app and flows the event through the same pipeline as a live WS
  /// frame. Without a freshness check the sheet would slide up showing a
  /// dead offer; the technician would swipe accept and hit a server-side
  /// 4xx because the booking has already flipped to REJECTED via the SLA
  /// Celery task.
  ///
  /// Since flag #19 closed (2026-05-03), `SystemEventNotifier`'s pipeline
  /// filter handles the common case using envelope-level `expires_at`
  /// before the event ever reaches this mapper. This per-feature derivation
  /// (`event.timestamp + expires_in_seconds`) stays as a second gate —
  /// "two checks for the same thing on different layers" is the right
  /// shape for a privacy/UX-adjacent path, and the cost is three lines.
  /// It also covers the residual case where a backend-side glitch ships
  /// an envelope without `expires_at` despite the payload carrying
  /// `expires_in_seconds` (rollout-edge or legacy `EventLog` replay).
  ///
  /// [now] is injectable for tests. Production callers omit it and the
  /// mapper falls back to `DateTime.now().toUtc()`. Wall-clock skew is the
  /// known failure mode: a phone whose clock is several minutes off would
  /// either reject fresh offers or keep dead ones. Phones are typically
  /// NTP-synced; the residual risk is acknowledged here and is the reason
  /// the pipeline-level filter (which can anchor on server time observed
  /// from live WS frames) is the proper home for this check.
  static JobNewRequest? fromSystemEvent(
    SystemEventEntity event, {
    DateTime? now,
  }) {
    final JobNewRequestPayloadModel model;
    try {
      model = JobNewRequestPayloadModel.fromJson(event.payload);
    } catch (e, stack) {
      log(
        'Dropping malformed job_new_request payload: $e',
        name: _logName,
        stackTrace: stack,
      );
      return null;
    }

    final payoutRupees = int.tryParse(model.payout);
    if (payoutRupees == null) {
      log(
        'Non-numeric payout "${model.payout}" on job ${model.jobId}; dropping.',
        name: _logName,
      );
      return null;
    }

    final DateTime scheduledStart;
    try {
      scheduledStart = DateTime.parse(model.scheduledStartIso);
    } catch (e) {
      log(
        'Unparseable scheduled_start_iso "${model.scheduledStartIso}" on job '
        '${model.jobId}; dropping.',
        name: _logName,
      );
      return null;
    }

    // §2.5: a null `bookingType` (replayed pre-rollout EventLog row) defaults
    // to `laborGig`'s neutral layout. Keeping the default here means widgets
    // never branch on null.
    final bookingType = _resolveBookingType(model.bookingType, model.jobId);

    // Anchor the countdown on the server's envelope timestamp (the time the
    // backend broadcast the event) plus the SLA window. Anchoring on receipt
    // time would give the technician slightly more time than the server's
    // Celery SLA task allows; a tap-just-past-expiry would 409 against the
    // server's earlier-fired timeout (BOOKINGS_API.md §1.3 → 409
    // `booking_no_longer_available` → `OfferNoLongerAvailable` failure).
    final slaWindow = Duration(seconds: model.expiresInSeconds);
    final expiresAt = event.timestamp.add(slaWindow);

    final effectiveNow = now ?? DateTime.now().toUtc();
    if (!effectiveNow.isBefore(expiresAt)) {
      log(
        'Dropping expired job_new_request: jobId=${model.jobId} '
        'expiredAt=${expiresAt.toIso8601String()} '
        'now=${effectiveNow.toIso8601String()}',
        name: _logName,
      );
      return null;
    }

    return JobNewRequest(
      jobId: model.jobId,
      serviceName: model.serviceName,
      bookingType: bookingType,
      payoutRupees: payoutRupees,
      payoutContext: model.payoutContext,
      scheduledStart: scheduledStart,
      expiresAt: expiresAt,
      slaWindow: slaWindow,
      locationLabel: model.locationLabel,
    );
  }

  static BookingType _resolveBookingType(String? wire, int jobId) {
    if (wire == null) return BookingType.laborGig;
    final resolved = _bookingTypeLookup[wire];
    if (resolved == null) {
      log(
        'Unknown booking_type "$wire" on job $jobId; defaulting to laborGig.',
        name: _logName,
      );
      return BookingType.laborGig;
    }
    return resolved;
  }
}
