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
  static JobNewRequest? fromSystemEvent(SystemEventEntity event) {
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
    // Celery SLA task allows; once the accept endpoint lands a tap-just-past-
    // expiry would 409 against the server's earlier-fired timeout.
    final expiresAt =
        event.timestamp.add(Duration(seconds: model.expiresInSeconds));

    return JobNewRequest(
      jobId: model.jobId,
      serviceName: model.serviceName,
      bookingType: bookingType,
      payoutRupees: payoutRupees,
      payoutContext: model.payoutContext,
      scheduledStart: scheduledStart,
      expiresAt: expiresAt,
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
