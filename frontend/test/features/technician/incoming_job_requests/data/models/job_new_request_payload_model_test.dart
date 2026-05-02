import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/incoming_job_requests/data/models/job_new_request_payload_model.dart';

void main() {
  group('JobNewRequestPayloadModel', () {
    // Wire spec: backend/bookings/api/BOOKINGS_API.md §1.2
    final freshPayload = <String, dynamic>{
      'job_id': 99482,
      'service_name': 'AC Deep Wash',
      'booking_type': 'FIXED_GIG',
      'scheduled_start_iso': '2026-04-08T05:00:00Z',
      'payout': '1200',
      'payout_context': 'Fixed-price gig — full payout',
      'expires_in_seconds': 900,
      'ui_location_label': 'Gulberg, Lahore',
    };

    test('fromJson — fresh §1.2 payload round-trips all 8 fields', () {
      final model = JobNewRequestPayloadModel.fromJson(freshPayload);

      expect(model.jobId, 99482);
      expect(model.serviceName, 'AC Deep Wash');
      expect(model.bookingType, 'FIXED_GIG');
      expect(model.scheduledStartIso, '2026-04-08T05:00:00Z');
      expect(model.payout, '1200');
      expect(model.payoutContext, 'Fixed-price gig — full payout');
      expect(model.expiresInSeconds, 900);
      expect(model.locationLabel, 'Gulberg, Lahore');
    });

    test(
      'fromJson — §2.5 replayed payload (no booking_type, no payout_context, '
      'no ui_location_label) leaves all three fields null without throwing',
      () {
        final replay = Map<String, dynamic>.from(freshPayload)
          ..remove('booking_type')
          ..remove('payout_context')
          ..remove('ui_location_label');

        final model = JobNewRequestPayloadModel.fromJson(replay);

        expect(model.bookingType, isNull);
        expect(model.payoutContext, isNull);
        expect(model.locationLabel, isNull);
        // The other five fields remain populated; the model is still usable.
        expect(model.jobId, 99482);
        expect(model.expiresInSeconds, 900);
      },
    );

    test('fromJson — explicit null ui_location_label deserializes to null', () {
      // Backend echoes null when CustomerAddress.locality_label is null
      // (legacy address) or when the booking's address FK is detached.
      final withNullLocality = Map<String, dynamic>.from(freshPayload)
        ..['ui_location_label'] = null;

      final model = JobNewRequestPayloadModel.fromJson(withNullLocality);

      expect(model.locationLabel, isNull);
    });

    test('fromJson — missing required job_id throws', () {
      final broken = Map<String, dynamic>.from(freshPayload)..remove('job_id');

      expect(
        () => JobNewRequestPayloadModel.fromJson(broken),
        throwsA(anything),
      );
    });

    test('fromJson — wrong type for payout (int instead of string) throws', () {
      // The backend explicitly wires payout as a string for parse-fidelity;
      // an int on the wire would indicate a backend regression and must
      // surface loudly.
      final broken = Map<String, dynamic>.from(freshPayload)..['payout'] = 1200;

      expect(
        () => JobNewRequestPayloadModel.fromJson(broken),
        throwsA(anything),
      );
    });
  });
}
