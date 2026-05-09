// Tests for `BookingDetailRepositoryImpl`.
//
// The repository is the critical layer for the orchestrator's error
// pipeline (CLAUDE.md): every HTTP / network failure must be mapped to
// a typed `BookingDetailFailure` sealed subclass before reaching the
// presentation layer. The screen pattern-matches on the type — raw
// `HttpFailure`s leaking through would crash the switch.
//
// Also covers the offline-first contract:
//   * SocketException + cache present → cached entity (no throw).
//   * SocketException + no cache       → BookingDetailOfflineNoCache.
//   * Cached row that mapper rejects   → cache cleared + offline failure.
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/orchestrator/data/datasources/booking_detail_local_data_source.dart';
import 'package:frontend/features/orchestrator/data/datasources/booking_detail_remote_data_source.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/data/repositories/booking_detail_repository_impl.dart';
import 'package:frontend/features/orchestrator/domain/failures/booking_detail_failure.dart';
import 'package:mocktail/mocktail.dart';

import '../../_helpers/booking_detail_fixture.dart';

class _MockRemote extends Mock implements IBookingDetailRemoteDataSource {}

class _MockLocal extends Mock implements IBookingDetailLocalDataSource {}

class _FakeModel extends Fake implements BookingDetailModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeModel());
  });

  late _MockRemote remote;
  late _MockLocal local;
  late BookingDetailRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    when(() => local.cache(any(), any())).thenAnswer((_) async {});
    when(() => local.clear(any())).thenAnswer((_) async {});
    when(() => local.read(any())).thenAnswer((_) async => null);
    repo = BookingDetailRepositoryImpl(
      remote: remote,
      local: local,
      currentUserId: 7,
    );
  });

  BookingDetailModel model({int customerId = 7}) =>
      BookingDetailModel.fromJson(bookingDetailJson(customerId: customerId));

  group('happy path', () {
    test('remote success returns mapped domain entity', () async {
      when(() => remote.fetch(42)).thenAnswer((_) async => model());
      final out = await repo.getBookingDetail(42);
      expect(out.id, 42);
    });

    test('remote success caches the wire model (best-effort)', () async {
      final m = model();
      when(() => remote.fetch(42)).thenAnswer((_) async => m);
      await repo.getBookingDetail(42);
      // The cache call may be in-flight; .ignore() returns sync. Either
      // way mocktail's verify is queued so it's deterministic.
      verify(() => local.cache(42, m)).called(1);
    });
  });

  group('HTTP error mapping', () {
    test('404 → BookingDetailNotFound(bookingId)', () async {
      when(() => remote.fetch(42)).thenThrow(
        const HttpFailure(
          statusCode: 404,
          code: 'booking_not_found',
          message: 'gone',
          errors: {},
        ),
      );
      await expectLater(
        repo.getBookingDetail(42),
        throwsA(
          isA<BookingDetailNotFound>().having(
            (f) => f.bookingId,
            'bookingId',
            42,
          ),
        ),
      );
    });

    test('403 + not_a_participant → BookingDetailNotParticipant', () async {
      when(() => remote.fetch(42)).thenThrow(
        const HttpFailure(
          statusCode: 403,
          code: 'not_a_participant',
          message: 'nope',
          errors: {},
        ),
      );
      await expectLater(
        repo.getBookingDetail(42),
        throwsA(isA<BookingDetailNotParticipant>()),
      );
    });

    test('500 → BookingDetailServerFailure', () async {
      when(() => remote.fetch(42)).thenThrow(
        const HttpFailure(
          statusCode: 500,
          code: 'server_error',
          message: 'oops',
          errors: {},
        ),
      );
      await expectLater(
        repo.getBookingDetail(42),
        throwsA(isA<BookingDetailServerFailure>()),
      );
    });

    test('502 → BookingDetailServerFailure (any 5xx)', () async {
      when(() => remote.fetch(42)).thenThrow(
        const HttpFailure(
          statusCode: 502,
          code: 'bad_gateway',
          message: 'gateway',
          errors: {},
        ),
      );
      await expectLater(
        repo.getBookingDetail(42),
        throwsA(isA<BookingDetailServerFailure>()),
      );
    });

    test('400 with non-known code → UnknownBookingDetailFailure', () async {
      when(() => remote.fetch(42)).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'bad',
          errors: {},
        ),
      );
      await expectLater(
        repo.getBookingDetail(42),
        throwsA(
          isA<UnknownBookingDetailFailure>().having(
            (f) => f.message,
            'message',
            'bad',
          ),
        ),
      );
    });
  });

  group('offline-first', () {
    test('SocketException with cache returns cached domain entity', () async {
      when(() => remote.fetch(42)).thenThrow(const SocketException('offline'));
      when(() => local.read(42)).thenAnswer((_) async => model());

      final out = await repo.getBookingDetail(42);
      expect(out.id, 42);
    });

    test(
      'SocketException with no cache → BookingDetailOfflineNoCache',
      () async {
        when(
          () => remote.fetch(42),
        ).thenThrow(const SocketException('offline'));
        when(() => local.read(42)).thenAnswer((_) async => null);

        await expectLater(
          repo.getBookingDetail(42),
          throwsA(isA<BookingDetailOfflineNoCache>()),
        );
      },
    );

    test(
      'SocketException + cached row that mapper rejects evicts cache',
      () async {
        // Construct a model the mapper will reject. The mapper throws on
        // a malformed Decimal-string in `pricing.inspection_fee`. This
        // simulates a schema-drift cache row that we can no longer
        // translate. The repository must evict + throw offline failure
        // so the user doesn't get an "Error" loop on every offline mount.
        final badJson = bookingDetailJson();
        (badJson['pricing'] as Map)['inspection_fee'] = 'not-a-number';
        final badModel = BookingDetailModel.fromJson(badJson);

        when(
          () => remote.fetch(42),
        ).thenThrow(const SocketException('offline'));
        when(() => local.read(42)).thenAnswer((_) async => badModel);

        await expectLater(
          repo.getBookingDetail(42),
          throwsA(isA<BookingDetailOfflineNoCache>()),
        );
        verify(() => local.clear(42)).called(1);
      },
    );
  });

  group('online + bad cache', () {
    test(
      'remote ok but mapper throws → cache evicted, error rethrown',
      () async {
        // The repo caches BEFORE mapping. If the map step fails (schema
        // drift on a freshly-served wire model), the cache row is also
        // evicted so we don't serve a known-bad row on the next offline
        // mount. The original error propagates so the caller can see it.
        final badJson = bookingDetailJson();
        (badJson['pricing'] as Map)['inspection_fee'] = 'not-a-number';
        final badModel = BookingDetailModel.fromJson(badJson);
        when(() => remote.fetch(42)).thenAnswer((_) async => badModel);

        await expectLater(
          repo.getBookingDetail(42),
          throwsA(isA<UnknownBookingDetailFailure>()),
        );
        verify(() => local.cache(42, badModel)).called(1);
        verify(() => local.clear(42)).called(1);
      },
    );
  });

  test('unexpected exception bucket → UnknownBookingDetailFailure', () async {
    when(() => remote.fetch(42)).thenThrow(StateError('weird'));
    await expectLater(
      repo.getBookingDetail(42),
      throwsA(isA<UnknownBookingDetailFailure>()),
    );
  });
}
