// Tests for ScheduledJobsRepositoryImpl — the network-first +
// cache-fallback orchestrator and the wire-code → typed-failure switch
// (step 2 of the 4-step CLAUDE.md error pipeline).
//
// Covers:
//   * getScheduledJobs happy: caches first page, NOT subsequent.
//   * SocketException first-page + cache hit → stale page with flags.
//   * SocketException first-page + no cache → OfflineNoCache.
//   * SocketException non-first-page → OfflineNoCache (no cache read).
//   * HTTP 5xx → ServerFailure.
//   * HTTP 400 with code → ValidationFailure carrying code+errors.
//   * HTTP 401/404/418 → Unknown.
//   * Cache-write failure swallowed (best-effort).
//   * Untyped exception → Unknown.
//   * Already-typed ScheduledJobsFailure rethrown verbatim.
//   * getCounts paths.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/technician/schedule/data/data_sources/scheduled_jobs_local_data_source.dart';
import 'package:frontend/features/technician/schedule/data/data_sources/scheduled_jobs_remote_data_source.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_job_model.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_jobs_counts_model.dart';
import 'package:frontend/features/technician/schedule/data/models/scheduled_jobs_list_response_model.dart';
import 'package:frontend/features/technician/schedule/data/repositories/scheduled_jobs_repository_impl.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_job_segment.dart';
import 'package:frontend/features/technician/schedule/domain/failures/scheduled_jobs_failure.dart';

// ─── Fakes ───────────────────────────────────────────────────────────

class _FakeRemote implements IScheduledJobsRemoteDataSource {
  Object? toThrow;
  ScheduledJobsListResponseModel? listResponse;
  ScheduledJobsCountsModel? countsResponse;

  ScheduledJobSegment? capturedSegment;
  String? capturedCursor;
  int? capturedPageSize;
  List<BookingStatus>? capturedStatusFilter;
  int listCallCount = 0;
  int countsCallCount = 0;

  @override
  Future<ScheduledJobsListResponseModel> getScheduledJobs({
    required ScheduledJobSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) async {
    listCallCount++;
    capturedSegment = segment;
    capturedCursor = cursor;
    capturedPageSize = pageSize;
    capturedStatusFilter = statusFilter;
    if (toThrow != null) throw toThrow!;
    return listResponse!;
  }

  @override
  Future<ScheduledJobsCountsModel> getCounts() async {
    countsCallCount++;
    if (toThrow != null) throw toThrow!;
    return countsResponse!;
  }
}

class _FakeLocal implements IScheduledJobsLocalDataSource {
  CachedScheduledJobsPage? cached;
  Object? cacheWriteThrow;
  int cacheWriteCount = 0;
  int cacheReadCount = 0;
  int clearCount = 0;

  @override
  Future<void> cacheFirstPage(
    ScheduledJobSegment segment,
    ScheduledJobsListResponseModel response,
  ) async {
    cacheWriteCount++;
    if (cacheWriteThrow != null) throw cacheWriteThrow!;
  }

  @override
  Future<CachedScheduledJobsPage?> getCachedFirstPage(
    ScheduledJobSegment segment,
  ) async {
    cacheReadCount++;
    return cached;
  }

  @override
  Future<void> clear() async {
    clearCount++;
  }
}

// ─── Sample data ─────────────────────────────────────────────────────

ScheduledJobsListResponseModel _sampleResponse({
  String? nextCursor,
  bool hasMore = false,
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

ScheduledJobsCountsModel _sampleCounts({int upcoming = 1, int past = 12}) {
  return ScheduledJobsCountsModel(
    upcoming: upcoming,
    past: past,
    serverTime: '2026-05-05T12:34:56Z',
  );
}

// ─── Tests ───────────────────────────────────────────────────────────

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late ScheduledJobsRepositoryImpl repo;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repo = ScheduledJobsRepositoryImpl(remote: remote, local: local);
  });

  // ──────────────────────────────────────────────────────────────────
  // getScheduledJobs — happy paths
  // ──────────────────────────────────────────────────────────────────

  group('getScheduledJobs — happy path', () {
    test('returns mapped page from network', () async {
      remote.listResponse = _sampleResponse(itemId: 42, hasMore: false);

      final page = await repo.getScheduledJobs(
        segment: ScheduledJobSegment.upcoming,
      );

      expect(page.items, hasLength(1));
      expect(page.items.first.id, 42);
      expect(page.items.first.status, BookingStatus.confirmed);
      expect(page.isStaleCache, isFalse);
      expect(page.cachedAt, isNull);
    });

    test('caches first page on success', () async {
      remote.listResponse = _sampleResponse();

      await repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming);

      expect(local.cacheWriteCount, 1);
    });

    test('does NOT cache a subsequent page (cursor != null)', () async {
      remote.listResponse = _sampleResponse();

      await repo.getScheduledJobs(
        segment: ScheduledJobSegment.upcoming,
        cursor: 'cur-x',
      );

      expect(local.cacheWriteCount, 0);
    });

    test(
      'forwards segment / cursor / pageSize / statusFilter to remote',
      () async {
        remote.listResponse = _sampleResponse();

        await repo.getScheduledJobs(
          segment: ScheduledJobSegment.past,
          cursor: 'cur-x',
          pageSize: 50,
          statusFilter: const [BookingStatus.completed],
        );

        expect(remote.capturedSegment, ScheduledJobSegment.past);
        expect(remote.capturedCursor, 'cur-x');
        expect(remote.capturedPageSize, 50);
        expect(remote.capturedStatusFilter, const [BookingStatus.completed]);
      },
    );

    test('cache-write failure is swallowed (best-effort)', () async {
      remote.listResponse = _sampleResponse();
      local.cacheWriteThrow = Exception('disk full');

      final page = await repo.getScheduledJobs(
        segment: ScheduledJobSegment.upcoming,
      );
      expect(page.items, hasLength(1));
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // getScheduledJobs — SocketException
  // ──────────────────────────────────────────────────────────────────

  group('getScheduledJobs — SocketException', () {
    test(
      'first page + cache hit → stale page with isStaleCache=true',
      () async {
        remote.toThrow = const SocketException('offline');
        final cachedAt = DateTime.utc(2026, 5, 5, 12, 0, 0);
        local.cached = CachedScheduledJobsPage(
          response: _sampleResponse(itemId: 7, hasMore: false),
          cachedAt: cachedAt,
        );

        final page = await repo.getScheduledJobs(
          segment: ScheduledJobSegment.upcoming,
        );

        expect(page.items.first.id, 7);
        expect(page.isStaleCache, isTrue);
        expect(page.cachedAt, cachedAt);
        expect(local.cacheReadCount, 1);
      },
    );

    test('first page + no cache → OfflineNoCache', () async {
      remote.toThrow = const SocketException('offline');
      local.cached = null;

      await expectLater(
        repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming),
        throwsA(isA<ScheduledJobsOfflineNoCache>()),
      );
    });

    test(
      'non-first page (cursor != null) → OfflineNoCache without cache read',
      () async {
        remote.toThrow = const SocketException('offline');
        local.cached = CachedScheduledJobsPage(
          response: _sampleResponse(),
          cachedAt: DateTime.utc(2026, 5, 5, 12, 0, 0),
        );

        await expectLater(
          repo.getScheduledJobs(
            segment: ScheduledJobSegment.upcoming,
            cursor: 'cur-x',
          ),
          throwsA(isA<ScheduledJobsOfflineNoCache>()),
        );
        expect(local.cacheReadCount, 0);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────
  // getScheduledJobs — HTTP error mapping
  // ──────────────────────────────────────────────────────────────────

  group('getScheduledJobs — HTTP error → typed failure', () {
    test(
      '400 invalid_cursor → ValidationFailure carrying code+errors',
      () async {
        remote.toThrow = const HttpFailure(
          statusCode: 400,
          code: 'invalid_cursor',
          message: 'Cursor is malformed.',
          errors: {
            'cursor': ['Cursor is malformed.'],
          },
        );

        try {
          await repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming);
          fail('expected ValidationFailure');
        } on ScheduledJobsValidationFailure catch (e) {
          expect(e.code, 'invalid_cursor');
          expect(e.errors['cursor'], ['Cursor is malformed.']);
          expect(e.message, 'Cursor is malformed.');
        }
      },
    );

    test('400 invalid_status_filter → ValidationFailure', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 400,
        code: 'invalid_status_filter',
        message: 'Invalid query parameters.',
        errors: {
          'status': ['Unknown status value(s): WAITING.'],
        },
      );

      try {
        await repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming);
        fail('expected ValidationFailure');
      } on ScheduledJobsValidationFailure catch (e) {
        expect(e.code, 'invalid_status_filter');
      }
    });

    test('400 with empty message defaults to "Invalid request."', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 400,
        code: 'validation_error',
        message: '',
      );

      try {
        await repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming);
        fail('expected ValidationFailure');
      } on ScheduledJobsValidationFailure catch (e) {
        expect(e.message, 'Invalid request.');
      }
    });

    test('500 → ServerFailure', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 500,
        code: 'server_error',
        message: 'boom',
      );

      await expectLater(
        repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming),
        throwsA(isA<ScheduledJobsServerFailure>()),
      );
    });

    test('503 → ServerFailure (any 5xx)', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 503,
        code: 'server_error',
        message: 'unavailable',
      );

      await expectLater(
        repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming),
        throwsA(isA<ScheduledJobsServerFailure>()),
      );
    });

    test('401 → Unknown (auth-state mismatch)', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 401,
        code: 'unauthorized',
        message: 'Unauthorized.',
      );
      try {
        await repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming);
        fail('expected UnknownScheduledJobsFailure');
      } on UnknownScheduledJobsFailure catch (e) {
        expect(e.message, 'Unauthorized.');
      }
    });

    test(
      '403 → Unknown (non-tech user — happens when wrong-role boot-hook '
      'wakes the provider)',
      () async {
        remote.toThrow = const HttpFailure(
          statusCode: 403,
          code: 'permission_denied',
          message: 'User is not a registered technician.',
        );
        await expectLater(
          repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming),
          throwsA(isA<UnknownScheduledJobsFailure>()),
        );
      },
    );

    test('404 → Unknown (deployment mismatch)', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 404,
        code: 'not_found',
        message: 'Not found.',
      );
      await expectLater(
        repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming),
        throwsA(isA<UnknownScheduledJobsFailure>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // getScheduledJobs — propagation policy
  // ──────────────────────────────────────────────────────────────────

  group('getScheduledJobs — propagation policy', () {
    test('untyped exception → Unknown (catch-all)', () async {
      remote.toThrow = const FormatException('weird body');
      await expectLater(
        repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming),
        throwsA(isA<UnknownScheduledJobsFailure>()),
      );
    });

    test('already-typed ScheduledJobsFailure rethrown verbatim', () async {
      remote.toThrow = const ScheduledJobsServerFailure();
      try {
        await repo.getScheduledJobs(segment: ScheduledJobSegment.upcoming);
        fail('expected ServerFailure');
      } on ScheduledJobsServerFailure {
        // pass
      } on UnknownScheduledJobsFailure {
        fail('repo double-wrapped a typed failure');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // getCounts
  // ──────────────────────────────────────────────────────────────────

  group('getCounts', () {
    test('happy path returns mapped counts', () async {
      remote.countsResponse = _sampleCounts(upcoming: 7, past: 13);

      final result = await repo.getCounts();

      expect(result.upcoming, 7);
      expect(result.past, 13);
    });

    test('SocketException → OfflineNoCache (no cache lookup)', () async {
      remote.toThrow = const SocketException('offline');

      await expectLater(
        repo.getCounts(),
        throwsA(isA<ScheduledJobsOfflineNoCache>()),
      );
      // Counts are intentionally never cached.
      expect(local.cacheReadCount, 0);
    });

    test('5xx → ServerFailure', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 500,
        code: 'server_error',
        message: 'boom',
      );

      await expectLater(
        repo.getCounts(),
        throwsA(isA<ScheduledJobsServerFailure>()),
      );
    });

    test('400 → ValidationFailure (defensive)', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 400,
        code: 'unexpected_400',
        message: 'odd',
      );
      await expectLater(
        repo.getCounts(),
        throwsA(isA<ScheduledJobsValidationFailure>()),
      );
    });

    test('untyped exception → Unknown', () async {
      remote.toThrow = const FormatException('garbage');
      await expectLater(
        repo.getCounts(),
        throwsA(isA<UnknownScheduledJobsFailure>()),
      );
    });

    test('already-typed ScheduledJobsFailure rethrown verbatim', () async {
      remote.toThrow = const ScheduledJobsServerFailure();
      try {
        await repo.getCounts();
        fail('expected ServerFailure');
      } on ScheduledJobsServerFailure {
        // pass
      } on UnknownScheduledJobsFailure {
        fail('repo double-wrapped a typed failure');
      }
    });
  });
}
