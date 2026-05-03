// Tests for `IncomingJobRepositoryImpl._mapFailure` — step 2 of the
// 4-step error pipeline (CLAUDE.md). Drives the repository with a
// capturing fake of the remote data source so we can throw arbitrary
// HttpFailures (and other exceptions) and assert the typed failure that
// surfaces.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/incoming_job_requests/data/datasources/incoming_job_remote_data_source.dart';
import 'package:frontend/features/technician/incoming_job_requests/data/repositories/incoming_job_repository_impl.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/failures/incoming_job_failure.dart';

/// Fake data source that throws a pre-set exception (or returns success).
class _FakeDataSource implements IIncomingJobRemoteDataSource {
  Object? toThrow;

  @override
  Future<void> acceptJobRequest(int jobId) async {
    if (toThrow != null) throw toThrow!;
  }

  @override
  Future<void> declineJobRequest(int jobId) async {
    if (toThrow != null) throw toThrow!;
  }
}

void main() {
  late _FakeDataSource ds;
  late IncomingJobRepositoryImpl repo;

  setUp(() {
    ds = _FakeDataSource();
    repo = IncomingJobRepositoryImpl(ds);
  });

  group('IncomingJobRepositoryImpl.acceptJobRequest — _mapFailure', () {
    test('successful call resolves to void without throwing', () async {
      // ds.toThrow stays null → success.
      await expectLater(repo.acceptJobRequest(42), completes);
    });

    test(
      '409 booking_no_longer_available → OfferNoLongerAvailable carrying '
      'the echoed current_status',
      () async {
        ds.toThrow = const HttpFailure(
          statusCode: 409,
          code: 'booking_no_longer_available',
          message: 'This job is no longer available.',
          errors: {
            'current_status': ['REJECTED'],
          },
        );
        try {
          await repo.acceptJobRequest(42);
          fail('expected OfferNoLongerAvailable');
        } on OfferNoLongerAvailable catch (e) {
          expect(e.currentStatus, 'REJECTED');
          expect(e.message, 'This job is no longer available.');
        }
      },
    );

    test(
      '409 with empty errors → OfferNoLongerAvailable with null currentStatus',
      () async {
        ds.toThrow = const HttpFailure(
          statusCode: 409,
          code: 'booking_no_longer_available',
          message: 'This job is no longer available.',
        );
        try {
          await repo.acceptJobRequest(42);
          fail('expected OfferNoLongerAvailable');
        } on OfferNoLongerAvailable catch (e) {
          expect(e.currentStatus, isNull);
        }
      },
    );

    test(
      '404 not_found → OfferNoLongerAvailable (IDOR-safe collapse — '
      'missing OR wrong-owner both mean "the offer is gone")',
      () async {
        ds.toThrow = const HttpFailure(
          statusCode: 404,
          code: 'not_found',
          message: 'Booking not found.',
        );
        try {
          await repo.acceptJobRequest(42);
          fail('expected OfferNoLongerAvailable');
        } on OfferNoLongerAvailable catch (e) {
          // Server didn't disclose row state — currentStatus must be null.
          expect(e.currentStatus, isNull);
        }
      },
    );

    test('500 → IncomingJobServerFailure', () async {
      ds.toThrow = const HttpFailure(
        statusCode: 500,
        code: 'server_error',
        message: 'Server error: 500',
      );
      await expectLater(
        repo.acceptJobRequest(42),
        throwsA(isA<IncomingJobServerFailure>()),
      );
    });

    test('503 → IncomingJobServerFailure (any 5xx maps the same)', () async {
      ds.toThrow = const HttpFailure(
        statusCode: 503,
        code: 'server_error',
        message: 'Service unavailable',
      );
      await expectLater(
        repo.acceptJobRequest(42),
        throwsA(isA<IncomingJobServerFailure>()),
      );
    });

    test('SocketException → IncomingJobNetworkFailure', () async {
      ds.toThrow = const SocketException('Network is unreachable');
      await expectLater(
        repo.acceptJobRequest(42),
        throwsA(isA<IncomingJobNetworkFailure>()),
      );
    });

    test(
      'HttpFailure with an unhandled code → UnknownIncomingJobFailure '
      'carrying the wire message',
      () async {
        ds.toThrow = const HttpFailure(
          statusCode: 418,
          code: 'teapot',
          message: 'I am a teapot.',
        );
        try {
          await repo.acceptJobRequest(42);
          fail('expected UnknownIncomingJobFailure');
        } on UnknownIncomingJobFailure catch (e) {
          expect(e.message, 'I am a teapot.');
        }
      },
    );

    test(
      'A nested IncomingJobFailure thrown directly is rethrown verbatim '
      '(no double-wrap as UnknownIncomingJobFailure)',
      () async {
        ds.toThrow = const OfferNoLongerAvailable(currentStatus: 'CANCELLED');
        try {
          await repo.acceptJobRequest(42);
          fail('expected the nested failure to propagate');
        } on OfferNoLongerAvailable catch (e) {
          expect(e.currentStatus, 'CANCELLED');
        }
      },
    );

    test('Untyped exception → UnknownIncomingJobFailure', () async {
      ds.toThrow = const FormatException('bogus json');
      await expectLater(
        repo.acceptJobRequest(42),
        throwsA(isA<UnknownIncomingJobFailure>()),
      );
    });
  });

  group('IncomingJobRepositoryImpl.declineJobRequest', () {
    // Decline routes through the same _execute helper, so we don't repeat
    // every mapping case — just confirm the wire-up.

    test('successful call resolves to void', () async {
      await expectLater(repo.declineJobRequest(42), completes);
    });

    test('409 maps to OfferNoLongerAvailable on decline too', () async {
      ds.toThrow = const HttpFailure(
        statusCode: 409,
        code: 'booking_no_longer_available',
        message: 'This job is no longer available.',
        errors: {
          'current_status': ['CONFIRMED'],
        },
      );
      try {
        await repo.declineJobRequest(42);
        fail('expected OfferNoLongerAvailable');
      } on OfferNoLongerAvailable catch (e) {
        expect(e.currentStatus, 'CONFIRMED');
      }
    });

    test('SocketException maps to network failure on decline', () async {
      ds.toThrow = const SocketException('offline');
      await expectLater(
        repo.declineJobRequest(42),
        throwsA(isA<IncomingJobNetworkFailure>()),
      );
    });
  });
}
