// Tests for `BookingDetailMapper.toDomain`.
//
// The mapper is the only place where:
//   * Wire decimal-strings ("1500.00") become integer rupees.
//   * The viewer role is derived from the auth user id.
//   * The new (cycle 2 #B1) `child_booking_id` field crosses from
//     wire to typed domain field.
//
// Each of those is a regression vector — the tests below pin them.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_orchestrator_role.dart';

import '../../_helpers/booking_detail_fixture.dart';

void main() {
  group('BookingDetailMapper.toDomain', () {
    test('viewer role is customer when customer.id == currentUserId', () {
      final model =
          BookingDetailModel.fromJson(bookingDetailJson(customerId: 7));
      final domain = BookingDetailMapper.toDomain(model, currentUserId: 7);
      expect(domain.viewerRole, BookingOrchestratorRole.customer);
    });

    test(
      'viewer role is technician when currentUserId differs from customer.id',
      () {
        // The technician sub-block carries TechnicianProfile.id (NOT
        // User.id), so it cannot be used for comparison. The mapper
        // derives "tech" by exclusion: server already 403's
        // non-participants, so anyone who got past auth and isn't the
        // customer must be the tech.
        final model = BookingDetailModel.fromJson(
            bookingDetailJson(customerId: 7, technicianId: 99));
        final domain =
            BookingDetailMapper.toDomain(model, currentUserId: 555);
        expect(domain.viewerRole, BookingOrchestratorRole.technician);
      },
    );

    test('childBookingId surfaces when present on the wire (#B-4)', () {
      // Cycle 2 regression: the model field was added but the mapper
      // could silently fail to forward it. Pin both the present and
      // null cases.
      final present = BookingDetailModel.fromJson(
          bookingDetailJson(childBookingId: 123));
      final domainPresent =
          BookingDetailMapper.toDomain(present, currentUserId: 7);
      expect(domainPresent.childBookingId, 123);

      final absent = BookingDetailModel.fromJson(bookingDetailJson());
      final domainAbsent =
          BookingDetailMapper.toDomain(absent, currentUserId: 7);
      expect(domainAbsent.childBookingId, isNull);
    });

    test('parentBookingId is preserved (sanity guard)', () {
      final model = BookingDetailModel.fromJson(
          bookingDetailJson(parentBookingId: 41));
      final domain = BookingDetailMapper.toDomain(model, currentUserId: 7);
      expect(domain.parentBookingId, 41);
    });

    test('decimal-string pricing coerces to integer rupees', () {
      // Pakistan market has no paisa — the mapper truncates ".00"
      // losslessly. A regression to int.parse would throw on the
      // decimal point.
      final model = BookingDetailModel.fromJson(bookingDetailJson());
      final domain = BookingDetailMapper.toDomain(model, currentUserId: 7);
      expect(domain.pricing.inspectionFee, 500);
      expect(domain.pricing.baseServicesTotal, isNull);
    });

    test('booking_items decode price_charged to int rupees (#A-1 guard)', () {
      // Cycle 2 #A-1: serializer used to reuse QuoteLineItemResponseSerializer
      // which expected `priced_at`. The wire field on the BookingItem path
      // is `price_charged`. This test pins the wire→domain conversion
      // through the mapper end-to-end.
      final model = BookingDetailModel.fromJson(bookingDetailJson(
        bookingItems: [
          {
            'id': 5,
            'sub_service_id': 11,
            'sub_service_name': 'AC top-up',
            'quantity': 2,
            'price_charged': '750.00',
            'line_total': '1500.00',
            'sourced_quote_id': 91,
          },
        ],
      ));
      final domain = BookingDetailMapper.toDomain(model, currentUserId: 7);
      expect(domain.bookingItems, hasLength(1));
      final item = domain.bookingItems.single;
      expect(item.id, 5);
      expect(item.priceCharged, 750);
      expect(item.lineTotal, 1500);
      expect(item.sourcedQuoteId, 91);
    });

    test('active_quote is null when wire field is null', () {
      final model = BookingDetailModel.fromJson(bookingDetailJson());
      final domain = BookingDetailMapper.toDomain(model, currentUserId: 7);
      expect(domain.activeQuote, isNull);
    });

    test('status string decodes via BookingStatus.fromWire', () {
      final model = BookingDetailModel.fromJson(
          bookingDetailJson(status: 'IN_PROGRESS'));
      final domain = BookingDetailMapper.toDomain(model, currentUserId: 7);
      expect(domain.status, BookingStatus.inProgress);
    });

    test('phase_timestamps parse non-null entries to DateTime', () {
      final model = BookingDetailModel.fromJson(bookingDetailJson());
      final domain = BookingDetailMapper.toDomain(model, currentUserId: 7);
      // accepted_at present in fixture, others null — verify the
      // typed-domain side has a real DateTime, not the wire string.
      expect(domain.phaseTimestamps.acceptedAt, isA<DateTime>());
      expect(domain.phaseTimestamps.completedAt, isNull);
    });
  });
}
