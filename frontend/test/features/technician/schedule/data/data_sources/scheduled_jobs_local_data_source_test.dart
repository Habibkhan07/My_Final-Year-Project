// Tests for ScheduledJobsLocalDataSource — SharedPreferences-backed
// first-page-only cache used by the offline-rescue path of the repo.
// Mirrors customer-side local-DS tests so drift between the two surfaces
// surfaces immediately.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/schedule/data/data_sources/scheduled_jobs_local_data_source.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_job_model.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_jobs_list_response_model.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_job_segment.dart';
import 'package:shared_preferences/shared_preferences.dart';

ScheduledJobsListResponseModel _sampleResponse({
  String nextCursor = 'cur-1',
  bool hasMore = true,
  int itemId = 42,
}) {
  return ScheduledJobsListResponseModel(
    items: [
      ScheduledJobModel(
        id: itemId,
        status: 'CONFIRMED',
        service: const ScheduledJobServiceModel(
          name: 'AC Repair',
          iconName: 'ac_repair',
        ),
        customer: const ScheduledJobCustomerModel(
          id: 109,
          displayName: 'Sara Ahmed',
          profilePictureUrl: null,
        ),
        addressLabel: 'Home — DHA Phase 5, Lahore',
        scheduledStart: '2026-05-06T15:00:00Z',
        scheduledEnd: '2026-05-06T17:00:00Z',
        createdAt: '2026-05-05T09:12:00Z',
        payout: const PayoutBlockModel(
          amount: 1620,
          context: 'After Rs. 405 commission',
          uiLabel: 'Rs. 1,620',
        ),
        ui: const ScheduledJobUiModel(
          badgeText: 'Confirmed',
          badgeTone: 'positive',
          headline: 'Booked with Sara Ahmed',
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
  late ScheduledJobsLocalDataSource ds;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    ds = ScheduledJobsLocalDataSource(prefs);
  });

  group('cacheFirstPage + getCachedFirstPage', () {
    test('round-trips a response envelope', () async {
      final response = _sampleResponse();

      await ds.cacheFirstPage(ScheduledJobSegment.upcoming, response);
      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);

      expect(cached, isNotNull);
      expect(cached!.response.items, hasLength(1));
      expect(cached.response.items.first.id, 42);
      expect(cached.response.nextCursor, 'cur-1');
      expect(cached.response.hasMore, isTrue);
      expect(cached.response.serverTime, '2026-05-05T12:34:56Z');
    });

    test('cachedAt is set near now() and round-trips', () async {
      final beforeWrite = DateTime.now().toUtc();
      await ds.cacheFirstPage(
        ScheduledJobSegment.upcoming,
        _sampleResponse(),
      );
      final afterWrite = DateTime.now().toUtc();

      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);
      expect(cached, isNotNull);
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
      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);
      expect(cached, isNull);
    });

    test(
      'per-segment isolation — caching upcoming does not overwrite past',
      () async {
        await ds.cacheFirstPage(
          ScheduledJobSegment.upcoming,
          _sampleResponse(itemId: 1),
        );
        await ds.cacheFirstPage(
          ScheduledJobSegment.past,
          _sampleResponse(itemId: 2),
        );

        final upcoming = await ds.getCachedFirstPage(
          ScheduledJobSegment.upcoming,
        );
        final past = await ds.getCachedFirstPage(ScheduledJobSegment.past);

        expect(upcoming!.response.items.first.id, 1);
        expect(past!.response.items.first.id, 2);
      },
    );

    test(
      'overwrite — caching upcoming twice keeps only the latest',
      () async {
        await ds.cacheFirstPage(
          ScheduledJobSegment.upcoming,
          _sampleResponse(itemId: 1),
        );
        await ds.cacheFirstPage(
          ScheduledJobSegment.upcoming,
          _sampleResponse(itemId: 2),
        );

        final cached = await ds.getCachedFirstPage(
          ScheduledJobSegment.upcoming,
        );
        expect(cached!.response.items.first.id, 2);
      },
    );
  });

  group('decode error / corrupt entry paths', () {
    Future<void> writeRaw(String segmentWire, String raw) async {
      await prefs.setString(
        'CACHED_SCHEDULED_JOBS_${segmentWire}_v1',
        raw,
      );
    }

    test('non-JSON blob returns null (treated as cache miss)', () async {
      await writeRaw('upcoming', 'definitely-not-json');
      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);
      expect(cached, isNull);
    });

    test('JSON without cached_at field returns null', () async {
      await writeRaw(
        'upcoming',
        jsonEncode({
          'response': {/* irrelevant */},
        }),
      );
      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);
      expect(cached, isNull);
    });

    test('JSON without response field returns null', () async {
      await writeRaw(
        'upcoming',
        jsonEncode({'cached_at': DateTime.now().toUtc().toIso8601String()}),
      );
      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);
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
      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);
      expect(cached, isNull);
    });

    test('response with missing required field returns null', () async {
      await writeRaw(
        'upcoming',
        jsonEncode({
          'cached_at': DateTime.now().toUtc().toIso8601String(),
          'response': {
            'next_cursor': null,
            'server_time': '2026-05-05T12:34:56Z',
            // missing items, has_more.
          },
        }),
      );
      final cached = await ds.getCachedFirstPage(ScheduledJobSegment.upcoming);
      expect(cached, isNull);
    });
  });

  group('clear', () {
    test('removes every cached segment', () async {
      await ds.cacheFirstPage(
        ScheduledJobSegment.upcoming,
        _sampleResponse(),
      );
      await ds.cacheFirstPage(ScheduledJobSegment.past, _sampleResponse());

      await ds.clear();

      expect(
        await ds.getCachedFirstPage(ScheduledJobSegment.upcoming),
        isNull,
      );
      expect(await ds.getCachedFirstPage(ScheduledJobSegment.past), isNull);
    });

    test('is a no-op when nothing is cached', () async {
      await ds.clear();
      expect(
        await ds.getCachedFirstPage(ScheduledJobSegment.upcoming),
        isNull,
      );
    });
  });

  group('versioned key (forward-compat)', () {
    test(
      'cache written under v1 is not read after a hypothetical bump',
      () async {
        await prefs.setString(
          'CACHED_SCHEDULED_JOBS_upcoming_v2',
          jsonEncode({
            'cached_at': DateTime.now().toUtc().toIso8601String(),
            'response': _sampleResponse().toJson(),
          }),
        );
        final cached = await ds.getCachedFirstPage(
          ScheduledJobSegment.upcoming,
        );
        expect(cached, isNull);
      },
    );
  });
}
