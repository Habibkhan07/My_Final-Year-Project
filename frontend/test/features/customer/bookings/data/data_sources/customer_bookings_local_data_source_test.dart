// Tests for CustomerBookingsLocalDataSource — the SharedPreferences-
// backed first-page-only cache used by the offline-rescue path of the
// repository.
//
// Covers exhaustively:
//   * Round-trip: cache then read same envelope.
//   * Per-segment isolation (caching upcoming doesn't overwrite past).
//   * Decode-error path: corrupted blob returns null (treated as miss).
//   * Missing cached_at returns null.
//   * Missing response returns null.
//   * Unparseable cached_at returns null.
//   * cachedAt timestamp is round-trippable.
//   * clear() removes every segment's entry.
//   * Versioned key — entries written under v1 are not read under a
//     hypothetical bumped suffix (forward-compat smoke test).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/data/data_sources/customer_bookings_local_data_source.dart';
import 'package:frontend/features/customer/bookings/data/models/bookings_list_response_model.dart';
import 'package:frontend/features/customer/bookings/data/models/customer_booking_model.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:shared_preferences/shared_preferences.dart';

BookingsListResponseModel _sampleResponse({
  String nextCursor = 'cur-1',
  bool hasMore = true,
  int itemId = 99482,
}) {
  return BookingsListResponseModel(
    items: [
      CustomerBookingModel(
        id: itemId,
        status: 'CONFIRMED',
        service: const BookingServiceModel(
          name: 'AC Repair',
          iconName: 'ac_repair',
        ),
        technician: const BookingTechnicianModel(
          id: 17,
          displayName: 'Ahmed Khan',
          profilePictureUrl: null,
        ),
        addressLabel: 'Home',
        scheduledStart: '2026-05-06T15:00:00Z',
        scheduledEnd: '2026-05-06T17:00:00Z',
        createdAt: '2026-05-05T09:12:00Z',
        price: const BookingPriceModel(
          amount: 2500,
          context: 'Fixed Price',
          uiLabel: 'Rs. 2,500',
        ),
        ui: const BookingUiModel(
          badgeText: 'Confirmed',
          badgeTone: 'positive',
          headline: 'Confirmed with Ahmed Khan',
        ),
      ),
    ],
    nextCursor: nextCursor,
    hasMore: hasMore,
    serverTime: '2026-05-05T12:34:56Z',
  );
}

void main() {
  late SharedPreferences prefs;
  late CustomerBookingsLocalDataSource ds;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    ds = CustomerBookingsLocalDataSource(prefs);
  });

  group('cacheFirstPage + getCachedFirstPage', () {
    test('round-trips a response envelope', () async {
      final response = _sampleResponse();

      await ds.cacheFirstPage(BookingSegment.upcoming, response);
      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);

      expect(cached, isNotNull);
      expect(cached!.response.items, hasLength(1));
      expect(cached.response.items.first.id, 99482);
      expect(cached.response.nextCursor, 'cur-1');
      expect(cached.response.hasMore, isTrue);
      expect(cached.response.serverTime, '2026-05-05T12:34:56Z');
    });

    test('cachedAt is set near now() and round-trips', () async {
      final beforeWrite = DateTime.now().toUtc();
      await ds.cacheFirstPage(BookingSegment.upcoming, _sampleResponse());
      final afterWrite = DateTime.now().toUtc();

      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached, isNotNull);
      // cachedAt is between the timestamps that bracketed the write.
      expect(
        cached!.cachedAt.isAfter(
          beforeWrite.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        cached.cachedAt.isBefore(afterWrite.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('miss returns null when nothing cached', () async {
      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached, isNull);
    });

    test(
      'per-segment isolation — caching upcoming does not overwrite past',
      () async {
        await ds.cacheFirstPage(
          BookingSegment.upcoming,
          _sampleResponse(itemId: 1),
        );
        await ds.cacheFirstPage(
          BookingSegment.past,
          _sampleResponse(itemId: 2),
        );

        final upcoming = await ds.getCachedFirstPage(BookingSegment.upcoming);
        final past = await ds.getCachedFirstPage(BookingSegment.past);

        expect(upcoming!.response.items.first.id, 1);
        expect(past!.response.items.first.id, 2);
      },
    );

    test('overwrite — caching upcoming twice keeps only the latest', () async {
      await ds.cacheFirstPage(
        BookingSegment.upcoming,
        _sampleResponse(itemId: 1),
      );
      await ds.cacheFirstPage(
        BookingSegment.upcoming,
        _sampleResponse(itemId: 2),
      );

      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached!.response.items.first.id, 2);
    });
  });

  group('decode error / corrupt entry paths', () {
    Future<void> writeRaw(String segmentWire, String raw) async {
      // Mirror the data source's key derivation; bumping the version
      // suffix here would bypass the v1-keyed read entirely.
      await prefs.setString('CACHED_CUSTOMER_BOOKINGS_${segmentWire}_v1', raw);
    }

    test('non-JSON blob returns null (treated as cache miss)', () async {
      await writeRaw('upcoming', 'definitely-not-json');
      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached, isNull);
    });

    test('JSON without cached_at field returns null', () async {
      await writeRaw(
        'upcoming',
        jsonEncode({
          'response': {/* irrelevant */},
        }),
      );
      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached, isNull);
    });

    test('JSON without response field returns null', () async {
      await writeRaw(
        'upcoming',
        jsonEncode({'cached_at': DateTime.now().toUtc().toIso8601String()}),
      );
      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached, isNull);
    });

    test('unparseable cached_at returns null', () async {
      await writeRaw(
        'upcoming',
        jsonEncode({
          'cached_at': 'not-an-iso-date',
          'response': _sampleResponse().toJson(),
        }),
      );
      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached, isNull);
    });

    test('response with missing required field returns null', () async {
      // Wire model expects every field; omitting `items` should fail to
      // parse and surface as a null cache (no throw escapes).
      await writeRaw(
        'upcoming',
        jsonEncode({
          'cached_at': DateTime.now().toUtc().toIso8601String(),
          'response': {
            // missing items, has_more, etc.
            'next_cursor': null,
            'server_time': '2026-05-05T12:34:56Z',
          },
        }),
      );
      final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
      expect(cached, isNull);
    });
  });

  group('clear', () {
    test('removes every cached segment', () async {
      await ds.cacheFirstPage(BookingSegment.upcoming, _sampleResponse());
      await ds.cacheFirstPage(BookingSegment.past, _sampleResponse());

      await ds.clear();

      expect(await ds.getCachedFirstPage(BookingSegment.upcoming), isNull);
      expect(await ds.getCachedFirstPage(BookingSegment.past), isNull);
    });

    test('is a no-op when nothing is cached', () async {
      // Should not throw.
      await ds.clear();
      expect(await ds.getCachedFirstPage(BookingSegment.upcoming), isNull);
    });
  });

  group('versioned key (forward-compat)', () {
    test(
      'cache written under v1 is not read after a hypothetical bump',
      () async {
        // Simulate a future schema bump: write under a custom prefix and
        // confirm the current data source can't see it.
        await prefs.setString(
          'CACHED_CUSTOMER_BOOKINGS_upcoming_v2',
          jsonEncode({
            'cached_at': DateTime.now().toUtc().toIso8601String(),
            'response': _sampleResponse().toJson(),
          }),
        );
        // Current implementation reads v1, so v2 entry is invisible.
        final cached = await ds.getCachedFirstPage(BookingSegment.upcoming);
        expect(cached, isNull);
      },
    );
  });
}
