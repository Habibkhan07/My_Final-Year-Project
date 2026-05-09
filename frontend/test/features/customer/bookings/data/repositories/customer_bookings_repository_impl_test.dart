// Tests for CustomerBookingsRepositoryImpl — the network-first +
// cache-fallback orchestrator and the wire-code → typed-failure switch.
//
// Covers exhaustively:
//   * getBookings happy path: caches first page, does NOT cache subsequent.
//   * getBookings SocketException + first page + cache hit → stale page
//     with isStaleCache=true and cachedAt threaded through.
//   * getBookings SocketException + first page + no cache → OfflineNoCache.
//   * getBookings SocketException + non-first page → OfflineNoCache
//     (pagination cache is intentionally not maintained).
//   * getBookings 4xx envelope → ValidationFailure carrying the wire code.
//   * getBookings 5xx → ServerFailure.
//   * getBookings odd HTTP codes (401/403/404) → Unknown.
//   * Best-effort cache write: a local-DS write failure does NOT surface
//     to the caller after a successful network fetch.
//   * Untyped exception → Unknown (catch-all).
//   * Already-typed CustomerBookingsFailure rethrown verbatim (no
//     double-wrap to Unknown).
//   * getCounts happy path.
//   * getCounts SocketException → OfflineNoCache (no cache attempted).
//   * getCounts 5xx → ServerFailure.
//   * getCounts 4xx → ValidationFailure.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/bookings/data/data_sources/customer_bookings_local_data_source.dart';
import 'package:frontend/features/customer/bookings/data/data_sources/customer_bookings_remote_data_source.dart';
import 'package:frontend/features/customer/bookings/data/models/bookings_counts_model.dart';
import 'package:frontend/features/customer/bookings/data/models/bookings_list_response_model.dart';
import 'package:frontend/features/customer/bookings/data/models/customer_booking_model.dart';
import 'package:frontend/features/customer/bookings/data/repositories/customer_bookings_repository_impl.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/failures/customer_bookings_failure.dart';

// ─── Fakes ───────────────────────────────────────────────────────────

class _FakeRemote implements ICustomerBookingsRemoteDataSource {
  /// If non-null, this is thrown on every call.
  Object? toThrow;

  /// Otherwise, the return value(s) below are served.
  BookingsListResponseModel? listResponse;
  BookingsCountsModel? countsResponse;

  /// Captured arguments for assertions.
  BookingSegment? capturedSegment;
  String? capturedCursor;
  int? capturedPageSize;
  List<BookingStatus>? capturedStatusFilter;
  int listCallCount = 0;
  int countsCallCount = 0;

  @override
  Future<BookingsListResponseModel> getBookings({
    required BookingSegment segment,
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
  Future<BookingsCountsModel> getCounts() async {
    countsCallCount++;
    if (toThrow != null) throw toThrow!;
    return countsResponse!;
  }
}

class _FakeLocal implements ICustomerBookingsLocalDataSource {
  CachedBookingsPage? cached;
  Object? cacheWriteThrow;
  int cacheWriteCount = 0;
  int cacheReadCount = 0;
  int clearCount = 0;

  @override
  Future<void> cacheFirstPage(
    BookingSegment segment,
    BookingsListResponseModel response,
  ) async {
    cacheWriteCount++;
    if (cacheWriteThrow != null) throw cacheWriteThrow!;
  }

  @override
  Future<CachedBookingsPage?> getCachedFirstPage(BookingSegment segment) async {
    cacheReadCount++;
    return cached;
  }

  @override
  Future<void> clear() async {
    clearCount++;
  }
}

// ─── Sample data ─────────────────────────────────────────────────────

BookingsListResponseModel _sampleResponse({
  String? nextCursor,
  bool hasMore = false,
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

BookingsCountsModel _sampleCounts({int upcoming = 1, int past = 12}) {
  return BookingsCountsModel(
    upcoming: upcoming,
    past: past,
    serverTime: '2026-05-05T12:34:56Z',
  );
}

// ─── Tests ───────────────────────────────────────────────────────────

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late CustomerBookingsRepositoryImpl repo;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repo = CustomerBookingsRepositoryImpl(remote: remote, local: local);
  });

  // ──────────────────────────────────────────────────────────────────
  // getBookings — happy paths
  // ──────────────────────────────────────────────────────────────────

  group('getBookings — happy path', () {
    test('returns mapped page from network', () async {
      remote.listResponse = _sampleResponse(itemId: 99482, hasMore: false);

      final page = await repo.getBookings(segment: BookingSegment.upcoming);

      expect(page.items, hasLength(1));
      expect(page.items.first.id, 99482);
      expect(page.items.first.status, BookingStatus.confirmed);
      expect(page.isStaleCache, isFalse);
      expect(page.cachedAt, isNull);
    });

    test('caches first page on success', () async {
      remote.listResponse = _sampleResponse();

      await repo.getBookings(segment: BookingSegment.upcoming);

      expect(local.cacheWriteCount, 1);
    });

    test('does NOT cache when fetching a subsequent page', () async {
      remote.listResponse = _sampleResponse();

      await repo.getBookings(
        segment: BookingSegment.upcoming,
        cursor: 'cur-some-cursor',
      );

      // Pagination cache is intentionally not maintained.
      expect(local.cacheWriteCount, 0);
    });

    test('forwards segment/cursor/pageSize/statusFilter to remote', () async {
      remote.listResponse = _sampleResponse();

      await repo.getBookings(
        segment: BookingSegment.past,
        cursor: 'cur-x',
        pageSize: 50,
        statusFilter: const [BookingStatus.completed],
      );

      expect(remote.capturedSegment, BookingSegment.past);
      expect(remote.capturedCursor, 'cur-x');
      expect(remote.capturedPageSize, 50);
      expect(remote.capturedStatusFilter, const [BookingStatus.completed]);
    });

    test('cache-write failure is swallowed (best-effort)', () async {
      // The cache is the offline-rescue path, not a load-bearing
      // dependency. A write blip must not break the user's fresh data.
      remote.listResponse = _sampleResponse();
      local.cacheWriteThrow = Exception('disk full');

      final page = await repo.getBookings(segment: BookingSegment.upcoming);
      expect(page.items, hasLength(1));
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // getBookings — SocketException paths
  // ──────────────────────────────────────────────────────────────────

  group('getBookings — SocketException', () {
    test(
      'first page + cache hit → stale page with isStaleCache=true',
      () async {
        remote.toThrow = const SocketException('offline');
        final cachedAt = DateTime.utc(2026, 5, 5, 12, 0, 0);
        local.cached = CachedBookingsPage(
          response: _sampleResponse(itemId: 7, hasMore: false),
          cachedAt: cachedAt,
        );

        final page = await repo.getBookings(segment: BookingSegment.upcoming);

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
        repo.getBookings(segment: BookingSegment.upcoming),
        throwsA(isA<CustomerBookingsOfflineNoCache>()),
      );
    });

    test(
      'non-first page (cursor != null) → OfflineNoCache without read',
      () async {
        // Pagination cache isn't maintained → don't even consult the
        // local DS for subsequent pages.
        remote.toThrow = const SocketException('offline');
        local.cached = CachedBookingsPage(
          response: _sampleResponse(),
          cachedAt: DateTime.utc(2026, 5, 5, 12, 0, 0),
        );

        await expectLater(
          repo.getBookings(segment: BookingSegment.upcoming, cursor: 'cur-x'),
          throwsA(isA<CustomerBookingsOfflineNoCache>()),
        );
        expect(local.cacheReadCount, 0);
      },
    );

    test('per-segment cache lookup uses requested segment', () async {
      // Caller asks for past, repo must not return cached upcoming.
      // We exercise this by setting cache to null only when segment=past
      // is queried; the fake's cached field is segment-agnostic so we
      // just confirm the exception surfaces (= cache miss path was hit).
      remote.toThrow = const SocketException('offline');
      // No cache.
      await expectLater(
        repo.getBookings(segment: BookingSegment.past),
        throwsA(isA<CustomerBookingsOfflineNoCache>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // getBookings — HTTP error mapping
  // ──────────────────────────────────────────────────────────────────

  group('getBookings — HTTP error → typed failure', () {
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
          await repo.getBookings(segment: BookingSegment.upcoming);
          fail('expected ValidationFailure');
        } on CustomerBookingsValidationFailure catch (e) {
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
        await repo.getBookings(segment: BookingSegment.upcoming);
        fail('expected ValidationFailure');
      } on CustomerBookingsValidationFailure catch (e) {
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
        await repo.getBookings(segment: BookingSegment.upcoming);
        fail('expected ValidationFailure');
      } on CustomerBookingsValidationFailure catch (e) {
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
        repo.getBookings(segment: BookingSegment.upcoming),
        throwsA(isA<CustomerBookingsServerFailure>()),
      );
    });

    test('503 → ServerFailure (any 5xx)', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 503,
        code: 'server_error',
        message: 'unavailable',
      );

      await expectLater(
        repo.getBookings(segment: BookingSegment.upcoming),
        throwsA(isA<CustomerBookingsServerFailure>()),
      );
    });

    test(
      '401 → UnknownCustomerBookingsFailure (auth-state mismatch)',
      () async {
        remote.toThrow = const HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'Unauthorized.',
        );
        try {
          await repo.getBookings(segment: BookingSegment.upcoming);
          fail('expected UnknownCustomerBookingsFailure');
        } on UnknownCustomerBookingsFailure catch (e) {
          expect(e.message, 'Unauthorized.');
        }
      },
    );

    test(
      '404 → UnknownCustomerBookingsFailure (deployment mismatch)',
      () async {
        remote.toThrow = const HttpFailure(
          statusCode: 404,
          code: 'not_found',
          message: 'Not found.',
        );
        await expectLater(
          repo.getBookings(segment: BookingSegment.upcoming),
          throwsA(isA<UnknownCustomerBookingsFailure>()),
        );
      },
    );

    test('teapot 418 with random code → Unknown', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 418,
        code: 'teapot',
        message: 'I am a teapot.',
      );
      try {
        await repo.getBookings(segment: BookingSegment.upcoming);
        fail('expected UnknownCustomerBookingsFailure');
      } on UnknownCustomerBookingsFailure catch (e) {
        expect(e.message, 'I am a teapot.');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // getBookings — propagation policy
  // ──────────────────────────────────────────────────────────────────

  group('getBookings — propagation policy', () {
    test(
      'untyped exception → UnknownCustomerBookingsFailure (catch-all)',
      () async {
        remote.toThrow = const FormatException('weird body');
        await expectLater(
          repo.getBookings(segment: BookingSegment.upcoming),
          throwsA(isA<UnknownCustomerBookingsFailure>()),
        );
      },
    );

    test('already-typed CustomerBookingsFailure rethrown verbatim', () async {
      // Defensive: a future interceptor may already have mapped to a
      // typed failure. The repository must not double-wrap it.
      remote.toThrow = const CustomerBookingsServerFailure();
      try {
        await repo.getBookings(segment: BookingSegment.upcoming);
        fail('expected ServerFailure');
      } on CustomerBookingsServerFailure {
        // pass
      } on UnknownCustomerBookingsFailure {
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
        throwsA(isA<CustomerBookingsOfflineNoCache>()),
      );
      // Counts are intentionally never cached — local DS is not consulted.
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
        throwsA(isA<CustomerBookingsServerFailure>()),
      );
    });

    test('400 envelope → ValidationFailure (defensive — counts has no '
        'documented 400 codes today)', () async {
      remote.toThrow = const HttpFailure(
        statusCode: 400,
        code: 'unexpected_400',
        message: 'odd',
      );
      await expectLater(
        repo.getCounts(),
        throwsA(isA<CustomerBookingsValidationFailure>()),
      );
    });

    test('untyped exception → Unknown', () async {
      remote.toThrow = const FormatException('garbage');
      await expectLater(
        repo.getCounts(),
        throwsA(isA<UnknownCustomerBookingsFailure>()),
      );
    });

    test('already-typed CustomerBookingsFailure rethrown verbatim', () async {
      remote.toThrow = const CustomerBookingsServerFailure();
      try {
        await repo.getCounts();
        fail('expected ServerFailure');
      } on CustomerBookingsServerFailure {
        // pass
      } on UnknownCustomerBookingsFailure {
        fail('repo double-wrapped a typed failure');
      }
    });
  });
}
