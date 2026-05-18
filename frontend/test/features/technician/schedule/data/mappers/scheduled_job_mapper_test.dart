// Tests for ScheduledJobMapper — the wire-model → domain-entity
// boundary for the technician Schedule feature. Mirrors customer-side
// mapper tests so drift between the two surfaces is caught early.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/technician/schedule/data/mappers/scheduled_job_mapper.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_job_model.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_jobs_counts_model.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_jobs_list_response_model.dart';

ScheduledJobModel _sample({
  String status = 'CONFIRMED',
  String tone = 'positive',
  String scheduledStart = '2026-05-06T15:00:00Z',
  String scheduledEnd = '2026-05-06T17:00:00Z',
  String createdAt = '2026-05-05T09:12:00Z',
  String? addressLabel = 'Home — DHA Phase 5, Lahore',
  String? profilePictureUrl,
  int payoutAmount = 1620,
  String payoutContext = 'After Rs. 405 commission',
  String payoutUiLabel = 'Rs. 1,620',
  String badgeText = 'Confirmed',
  String headline = 'Booked with Sara Ahmed',
}) {
  return ScheduledJobModel(
    id: 42,
    status: status,
    service: const ScheduledJobServiceModel(
      name: 'AC Repair',
      iconName: 'ac_repair',
    ),
    customer: ScheduledJobCustomerModel(
      id: 109,
      displayName: 'Sara Ahmed',
      profilePictureUrl: profilePictureUrl,
    ),
    addressLabel: addressLabel,
    scheduledStart: scheduledStart,
    scheduledEnd: scheduledEnd,
    createdAt: createdAt,
    payout: PayoutBlockModel(
      amount: payoutAmount,
      context: payoutContext,
      uiLabel: payoutUiLabel,
    ),
    ui: ScheduledJobUiModel(
      badgeText: badgeText,
      badgeTone: tone,
      headline: headline,
    ),
  );
}

void main() {
  group('ScheduledJobMapper.fromModel — happy path', () {
    test('translates every documented field to typed entity', () {
      final entity = ScheduledJobMapper.fromModel(_sample());

      expect(entity.id, 42);
      expect(entity.status, BookingStatus.confirmed);
      expect(entity.service.name, 'AC Repair');
      expect(entity.service.iconName, 'ac_repair');
      expect(entity.customer.id, 109);
      expect(entity.customer.displayName, 'Sara Ahmed');
      // CustomerProfile has no profile_picture in v1.
      expect(entity.customer.profilePictureUrl, isNull);
      expect(entity.addressLabel, 'Home — DHA Phase 5, Lahore');
      expect(entity.scheduledStart, DateTime.parse('2026-05-06T15:00:00Z'));
      expect(entity.scheduledEnd, DateTime.parse('2026-05-06T17:00:00Z'));
      expect(entity.createdAt, DateTime.parse('2026-05-05T09:12:00Z'));
      expect(entity.payout.amount, 1620);
      expect(entity.payout.context, 'After Rs. 405 commission');
      expect(entity.payout.uiLabel, 'Rs. 1,620');
      expect(entity.ui.badgeText, 'Confirmed');
      expect(entity.ui.badgeTone, BookingUiTone.positive);
      expect(entity.ui.headline, 'Booked with Sara Ahmed');
    });

    test('null addressLabel passes through (SET_NULL on address FK)', () {
      final entity = ScheduledJobMapper.fromModel(
        _sample(addressLabel: null),
      );
      expect(entity.addressLabel, isNull);
    });

    test('non-null profilePictureUrl threads through (future-proofing)', () {
      // CustomerProfile has no avatar today, but the wire field exists.
      // If a future migration adds it, the FE must not drop the URL.
      final entity = ScheduledJobMapper.fromModel(
        _sample(profilePictureUrl: 'https://cdn.example/109.jpg'),
      );
      expect(entity.customer.profilePictureUrl, 'https://cdn.example/109.jpg');
    });
  });

  group('status string → BookingStatus enum', () {
    test('every documented status round-trips', () {
      for (final pair in const [
        // STATUS_AWAITING_TECH_ACCEPT wire value is literally 'AWAITING'.
        ('AWAITING', BookingStatus.awaiting),
        ('CONFIRMED', BookingStatus.confirmed),
        ('EN_ROUTE', BookingStatus.enRoute),
        ('ARRIVED', BookingStatus.arrived),
        ('INSPECTING', BookingStatus.inspecting),
        ('QUOTED', BookingStatus.quoted),
        ('IN_PROGRESS', BookingStatus.inProgress),
        ('COMPLETED', BookingStatus.completed),
        ('COMPLETED_INSPECTION_ONLY', BookingStatus.completedInspectionOnly),
        ('CANCELLED', BookingStatus.cancelled),
        ('TECH_DECLINED', BookingStatus.techDeclined),
        ('TECH_NO_RESPONSE', BookingStatus.techNoResponse),
        ('NO_SHOW', BookingStatus.noShow),
        ('DISPUTED', BookingStatus.disputed),
        ('PENDING', BookingStatus.pending),
      ]) {
        final entity = ScheduledJobMapper.fromModel(
          _sample(status: pair.$1),
        );
        expect(entity.status, pair.$2, reason: pair.$1);
      }
    });

    test('unknown status maps to BookingStatus.unknown (forward-compat)', () {
      final entity = ScheduledJobMapper.fromModel(
        _sample(status: 'QUOTE_PENDING'),
      );
      expect(entity.status, BookingStatus.unknown);
    });
  });

  group('badge tone string → BookingUiTone enum', () {
    test('every documented tone round-trips', () {
      for (final pair in const [
        ('positive', BookingUiTone.positive),
        ('warning', BookingUiTone.warning),
        ('negative', BookingUiTone.negative),
        ('neutral', BookingUiTone.neutral),
        ('info', BookingUiTone.info),
      ]) {
        final entity = ScheduledJobMapper.fromModel(_sample(tone: pair.$1));
        expect(entity.ui.badgeTone, pair.$2, reason: pair.$1);
      }
    });

    test('unknown tone maps to BookingUiTone.unknown', () {
      final entity = ScheduledJobMapper.fromModel(_sample(tone: 'electric'));
      expect(entity.ui.badgeTone, BookingUiTone.unknown);
    });
  });

  group('timestamps', () {
    test('parses ISO-8601 with Z suffix', () {
      final entity = ScheduledJobMapper.fromModel(
        _sample(scheduledStart: '2026-05-06T15:00:00Z'),
      );
      expect(entity.scheduledStart.toUtc(), DateTime.utc(2026, 5, 6, 15, 0, 0));
    });

    test('parses ISO-8601 with explicit offset', () {
      final entity = ScheduledJobMapper.fromModel(
        _sample(scheduledStart: '2026-05-06T20:00:00+05:00'),
      );
      expect(entity.scheduledStart.toUtc(), DateTime.utc(2026, 5, 6, 15, 0, 0));
    });

    test('unparseable string falls back to recent UTC (does not throw)', () {
      final before = DateTime.now().toUtc();
      final entity = ScheduledJobMapper.fromModel(
        _sample(scheduledStart: 'definitely-not-a-date'),
      );
      final after = DateTime.now().toUtc();
      expect(
        entity.scheduledStart.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        entity.scheduledStart.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('pageFromResponse — envelope thread-through', () {
    test('default flags: isStaleCache=false, cachedAt=null', () {
      final response = ScheduledJobsListResponseModel(
        items: [_sample()],
        nextCursor: 'cur-1',
        hasMore: true,
        serverTime: '2026-05-05T12:34:56Z',
      );

      final page = ScheduledJobMapper.pageFromResponse(response);

      expect(page.items, hasLength(1));
      expect(page.items.first.id, 42);
      expect(page.nextCursor, 'cur-1');
      expect(page.hasMore, isTrue);
      expect(page.serverTime, DateTime.parse('2026-05-05T12:34:56Z'));
      expect(page.isStaleCache, isFalse);
      expect(page.cachedAt, isNull);
    });

    test('stale cache flag and cachedAt thread through when supplied', () {
      final response = ScheduledJobsListResponseModel(
        items: [_sample()],
        nextCursor: null,
        hasMore: false,
        serverTime: '2026-05-05T12:34:56Z',
      );
      final cachedAt = DateTime.utc(2026, 5, 5, 12, 0, 0);

      final page = ScheduledJobMapper.pageFromResponse(
        response,
        isStaleCache: true,
        cachedAt: cachedAt,
      );

      expect(page.isStaleCache, isTrue);
      expect(page.cachedAt, cachedAt);
    });

    test('empty items list maps to empty page items', () {
      final response = ScheduledJobsListResponseModel(
        items: const [],
        nextCursor: null,
        hasMore: false,
        serverTime: '2026-05-05T12:34:56Z',
      );

      final page = ScheduledJobMapper.pageFromResponse(response);
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });

  group('countsFromModel', () {
    test('translates wire model verbatim', () {
      const model = ScheduledJobsCountsModel(
        upcoming: 7,
        past: 13,
        serverTime: '2026-05-05T12:34:56Z',
      );
      final entity = ScheduledJobMapper.countsFromModel(model);
      expect(entity.upcoming, 7);
      expect(entity.past, 13);
      expect(entity.serverTime, DateTime.parse('2026-05-05T12:34:56Z'));
    });

    test('zero counts are valid (no documented jobs)', () {
      const model = ScheduledJobsCountsModel(
        upcoming: 0,
        past: 0,
        serverTime: '2026-05-05T12:34:56Z',
      );
      final entity = ScheduledJobMapper.countsFromModel(model);
      expect(entity.upcoming, 0);
      expect(entity.past, 0);
    });
  });
}
