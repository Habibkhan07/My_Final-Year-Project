// Tests for CustomerBookingMapper — the wire-model → domain-entity
// boundary. Covers wire-string → typed enum translation, ISO →
// DateTime, the unparseable-timestamp fallback, and the page envelope
// thread-through (isStaleCache + cachedAt).
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/data/mappers/customer_booking_mapper.dart';
import 'package:frontend/features/customer/bookings/data/models/bookings_counts_model.dart';
import 'package:frontend/features/customer/bookings/data/models/bookings_list_response_model.dart';
import 'package:frontend/features/customer/bookings/data/models/customer_booking_model.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';

CustomerBookingModel _sample({
  String status = 'CONFIRMED',
  String tone = 'positive',
  String scheduledStart = '2026-05-06T15:00:00Z',
  String scheduledEnd = '2026-05-06T17:00:00Z',
  String createdAt = '2026-05-05T09:12:00Z',
  String? addressLabel = 'Home',
  String? profilePictureUrl,
  int amount = 2500,
  String uiLabel = 'Rs. 2,500',
}) {
  return CustomerBookingModel(
    id: 99482,
    status: status,
    service: const BookingServiceModel(
      name: 'AC Repair',
      iconName: 'ac_repair',
    ),
    technician: BookingTechnicianModel(
      id: 17,
      displayName: 'Ahmed Khan',
      profilePictureUrl: profilePictureUrl,
    ),
    addressLabel: addressLabel,
    scheduledStart: scheduledStart,
    scheduledEnd: scheduledEnd,
    createdAt: createdAt,
    price: BookingPriceModel(
      amount: amount,
      context: 'Fixed Price',
      uiLabel: uiLabel,
    ),
    ui: BookingUiModel(
      badgeText: 'Confirmed',
      badgeTone: tone,
      headline: 'Confirmed with Ahmed Khan',
    ),
  );
}

void main() {
  group('CustomerBookingMapper.fromModel — happy path', () {
    test('translates every documented field to typed entity', () {
      final entity = CustomerBookingMapper.fromModel(_sample());

      expect(entity.id, 99482);
      expect(entity.status, BookingStatus.confirmed);
      expect(entity.service.name, 'AC Repair');
      expect(entity.service.iconName, 'ac_repair');
      expect(entity.technician.id, 17);
      expect(entity.technician.displayName, 'Ahmed Khan');
      expect(entity.technician.profilePictureUrl, isNull);
      expect(entity.addressLabel, 'Home');
      expect(entity.scheduledStart, DateTime.parse('2026-05-06T15:00:00Z'));
      expect(entity.scheduledEnd, DateTime.parse('2026-05-06T17:00:00Z'));
      expect(entity.createdAt, DateTime.parse('2026-05-05T09:12:00Z'));
      expect(entity.price.amount, 2500);
      expect(entity.price.context, 'Fixed Price');
      expect(entity.price.uiLabel, 'Rs. 2,500');
      expect(entity.ui.badgeText, 'Confirmed');
      expect(entity.ui.badgeTone, BookingUiTone.positive);
      expect(entity.ui.headline, 'Confirmed with Ahmed Khan');
    });

    test('null addressLabel passes through', () {
      final entity = CustomerBookingMapper.fromModel(
        _sample(addressLabel: null),
      );
      expect(entity.addressLabel, isNull);
    });

    test('non-null profilePictureUrl threads through', () {
      final entity = CustomerBookingMapper.fromModel(
        _sample(profilePictureUrl: 'https://cdn.example/17.jpg'),
      );
      expect(entity.technician.profilePictureUrl, 'https://cdn.example/17.jpg');
    });
  });

  group('status string → BookingStatus enum', () {
    test('every documented status round-trips', () {
      for (final pair in const [
        ('AWAITING', BookingStatus.awaiting),
        ('CONFIRMED', BookingStatus.confirmed),
        ('COMPLETED', BookingStatus.completed),
        ('CANCELLED', BookingStatus.cancelled),
        ('TECH_DECLINED', BookingStatus.techDeclined),
        ('TECH_NO_RESPONSE', BookingStatus.techNoResponse),
        ('PENDING', BookingStatus.pending),
      ]) {
        final entity = CustomerBookingMapper.fromModel(
          _sample(status: pair.$1),
        );
        expect(entity.status, pair.$2, reason: pair.$1);
      }
    });

    test('unknown status string maps to BookingStatus.unknown', () {
      // Forward-compat: a future backend release adding QUOTE_PENDING
      // must NOT crash existing clients.
      final entity = CustomerBookingMapper.fromModel(
        _sample(status: 'QUOTE_PENDING'),
      );
      expect(entity.status, BookingStatus.unknown);
    });

    test('lowercase status is normalized to upper before lookup', () {
      // Defensive — backend always emits upper, but the mapper handles
      // mixed casing gracefully.
      final entity = CustomerBookingMapper.fromModel(
        _sample(status: 'confirmed'),
      );
      expect(entity.status, BookingStatus.confirmed);
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
        final entity = CustomerBookingMapper.fromModel(_sample(tone: pair.$1));
        expect(entity.ui.badgeTone, pair.$2, reason: pair.$1);
      }
    });

    test('unknown tone maps to BookingUiTone.unknown', () {
      final entity = CustomerBookingMapper.fromModel(_sample(tone: 'electric'));
      expect(entity.ui.badgeTone, BookingUiTone.unknown);
    });

    test('uppercase tone is normalized to lower', () {
      final entity = CustomerBookingMapper.fromModel(_sample(tone: 'POSITIVE'));
      expect(entity.ui.badgeTone, BookingUiTone.positive);
    });
  });

  group('timestamps', () {
    test('parses ISO-8601 with Z suffix', () {
      final entity = CustomerBookingMapper.fromModel(
        _sample(scheduledStart: '2026-05-06T15:00:00Z'),
      );
      expect(entity.scheduledStart.toUtc(), DateTime.utc(2026, 5, 6, 15, 0, 0));
    });

    test('parses ISO-8601 with explicit offset', () {
      final entity = CustomerBookingMapper.fromModel(
        _sample(scheduledStart: '2026-05-06T20:00:00+05:00'),
      );
      // 20:00 +05:00 == 15:00 UTC.
      expect(entity.scheduledStart.toUtc(), DateTime.utc(2026, 5, 6, 15, 0, 0));
    });

    test(
      'unparseable string falls back to a recent UTC DateTime, not throw',
      () {
        // The fallback policy: better to render a card with a stale-ish
        // date than drop the entire page on a single bad row.
        final beforeMap = DateTime.now().toUtc();
        final entity = CustomerBookingMapper.fromModel(
          _sample(scheduledStart: 'definitely-not-a-date'),
        );
        final afterMap = DateTime.now().toUtc();
        expect(
          entity.scheduledStart.isAfter(
            beforeMap.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          entity.scheduledStart.isBefore(
            afterMap.add(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      },
    );
  });

  group('pageFromResponse — envelope flag thread-through', () {
    test('default flags: isStaleCache=false, cachedAt=null', () {
      final response = BookingsListResponseModel(
        items: [_sample()],
        nextCursor: 'cur-1',
        hasMore: true,
        serverTime: '2026-05-05T12:34:56Z',
      );

      final page = CustomerBookingMapper.pageFromResponse(response);

      expect(page.items, hasLength(1));
      expect(page.items.first.id, 99482);
      expect(page.nextCursor, 'cur-1');
      expect(page.hasMore, isTrue);
      expect(page.serverTime, DateTime.parse('2026-05-05T12:34:56Z'));
      expect(page.isStaleCache, isFalse);
      expect(page.cachedAt, isNull);
    });

    test('stale cache flag and cachedAt thread through when supplied', () {
      final response = BookingsListResponseModel(
        items: [_sample()],
        nextCursor: null,
        hasMore: false,
        serverTime: '2026-05-05T12:34:56Z',
      );
      final cachedAt = DateTime.utc(2026, 5, 5, 12, 0, 0);

      final page = CustomerBookingMapper.pageFromResponse(
        response,
        isStaleCache: true,
        cachedAt: cachedAt,
      );

      expect(page.isStaleCache, isTrue);
      expect(page.cachedAt, cachedAt);
    });

    test('empty items list maps to empty page items', () {
      final response = BookingsListResponseModel(
        items: const [],
        nextCursor: null,
        hasMore: false,
        serverTime: '2026-05-05T12:34:56Z',
      );

      final page = CustomerBookingMapper.pageFromResponse(response);
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('unparseable serverTime falls back to a recent UTC DateTime', () {
      final response = BookingsListResponseModel(
        items: const [],
        nextCursor: null,
        hasMore: false,
        serverTime: 'not-iso',
      );
      final beforeMap = DateTime.now().toUtc();
      final page = CustomerBookingMapper.pageFromResponse(response);
      final afterMap = DateTime.now().toUtc();
      expect(
        page.serverTime.isAfter(beforeMap.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        page.serverTime.isBefore(afterMap.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('countsFromModel', () {
    test('translates wire model verbatim', () {
      const model = BookingsCountsModel(
        upcoming: 7,
        past: 13,
        serverTime: '2026-05-05T12:34:56Z',
      );
      final entity = CustomerBookingMapper.countsFromModel(model);
      expect(entity.upcoming, 7);
      expect(entity.past, 13);
      expect(entity.serverTime, DateTime.parse('2026-05-05T12:34:56Z'));
    });

    test('zero counts are valid', () {
      const model = BookingsCountsModel(
        upcoming: 0,
        past: 0,
        serverTime: '2026-05-05T12:34:56Z',
      );
      final entity = CustomerBookingMapper.countsFromModel(model);
      expect(entity.upcoming, 0);
      expect(entity.past, 0);
    });
  });
}
