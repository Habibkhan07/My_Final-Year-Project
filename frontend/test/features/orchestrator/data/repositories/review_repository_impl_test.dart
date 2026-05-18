// Tests for `ReviewRepositoryImpl` — the data-layer translator from
// wire failures (`HttpFailure` / `SocketException`) into the sealed
// `ReviewFailure` hierarchy the presentation layer consumes.
//
// Critical layer: a missed mapping here leaks `HttpFailure` up to the
// widget pattern-match, which would throw on the non-exhaustive switch.
// Cover every typed code + every fallback status.
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/orchestrator/data/datasources/review_remote_data_source.dart';
import 'package:frontend/features/orchestrator/data/models/review_model.dart';
import 'package:frontend/features/orchestrator/data/repositories/review_repository_impl.dart';
import 'package:frontend/features/orchestrator/domain/failures/review_failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements IReviewRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late ReviewRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = ReviewRepositoryImpl(remote: remote);
  });

  ReviewModel makeModel({int id = 1}) => ReviewModel(
        id: id,
        rating: 5,
        tags: const ['on_time'],
        text: 'great',
        createdAt: '2026-05-18T10:00:00Z',
        reviewerName: 'Test U.',
      );

  PredefinedTagBucketsModel _buckets() => const PredefinedTagBucketsModel(
        positive: [PredefinedTagModel(key: 'on_time', label: 'On time')],
        constructive: [PredefinedTagModel(key: 'late', label: 'Late')],
      );

  // ─── getSnapshot ──────────────────────────────────────────────────

  group('getSnapshot', () {
    test('maps wire model to domain snapshot', () async {
      when(() => remote.fetchSnapshot(1)).thenAnswer(
        (_) async => BookingReviewSnapshotModel(
          review: makeModel(),
          predefinedTags: _buckets(),
        ),
      );
      final snap = await repo.getSnapshot(1);
      expect(snap.review, isNotNull);
      expect(snap.review!.rating, 5);
      expect(snap.predefinedTags.positive.first.key, 'on_time');
    });

    test('null review survives mapping', () async {
      when(() => remote.fetchSnapshot(1)).thenAnswer(
        (_) async => BookingReviewSnapshotModel(
          review: null,
          predefinedTags: _buckets(),
        ),
      );
      final snap = await repo.getSnapshot(1);
      expect(snap.review, isNull);
    });

    test('SocketException → ReviewNetworkFailure', () async {
      when(() => remote.fetchSnapshot(1))
          .thenThrow(const SocketException('offline'));
      expect(repo.getSnapshot(1), throwsA(isA<ReviewNetworkFailure>()));
    });

    test('401 → ReviewUnauthorized', () async {
      when(() => remote.fetchSnapshot(1)).thenThrow(
        const HttpFailure(
          statusCode: 401, code: 'unauthenticated', message: 'no token',
        ),
      );
      expect(repo.getSnapshot(1), throwsA(isA<ReviewUnauthorized>()));
    });

    test('5xx → ReviewServerFailure', () async {
      when(() => remote.fetchSnapshot(1)).thenThrow(
        const HttpFailure(statusCode: 503, code: 'unknown', message: 'down'),
      );
      expect(repo.getSnapshot(1), throwsA(isA<ReviewServerFailure>()));
    });
  });

  // ─── submit ───────────────────────────────────────────────────────

  group('submit', () {
    setUp(() {
      when(() => remote.submitReview(
            bookingId: any(named: 'bookingId'),
            rating: any(named: 'rating'),
            tagKeys: any(named: 'tagKeys'),
            text: any(named: 'text'),
          )).thenAnswer((_) async => makeModel());
    });

    test('happy path returns domain review', () async {
      final review = await repo.submit(
        bookingId: 1, rating: 5, tagKeys: const ['on_time'], text: 'hi',
      );
      expect(review.id, 1);
      expect(review.rating, 5);
      expect(review.tags, ['on_time']);
    });

    test('409 review_already_submitted → ReviewAlreadySubmitted', () async {
      when(() => remote.submitReview(
            bookingId: any(named: 'bookingId'),
            rating: any(named: 'rating'),
            tagKeys: any(named: 'tagKeys'),
            text: any(named: 'text'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 409,
          code: 'review_already_submitted',
          message: '...',
        ),
      );
      expect(
        repo.submit(bookingId: 1, rating: 5, tagKeys: const [], text: ''),
        throwsA(isA<ReviewAlreadySubmitted>()),
      );
    });

    test('400 review_not_eligible preserves booking_status', () async {
      when(() => remote.submitReview(
            bookingId: any(named: 'bookingId'),
            rating: any(named: 'rating'),
            tagKeys: any(named: 'tagKeys'),
            text: any(named: 'text'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'review_not_eligible',
          message: '...',
          errors: {'booking_status': ['CONFIRMED']},
        ),
      );
      try {
        await repo.submit(bookingId: 1, rating: 5, tagKeys: const [], text: '');
        fail('should have thrown');
      } on ReviewNotEligible catch (e) {
        expect(e.currentBookingStatus, 'CONFIRMED');
      }
    });

    test('400 validation_error → ReviewValidationFailure with field map',
        () async {
      when(() => remote.submitReview(
            bookingId: any(named: 'bookingId'),
            rating: any(named: 'rating'),
            tagKeys: any(named: 'tagKeys'),
            text: any(named: 'text'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: '...',
          errors: {'tags': ['Unknown tag(s): foo']},
        ),
      );
      try {
        await repo.submit(
          bookingId: 1, rating: 5, tagKeys: const ['foo'], text: '',
        );
        fail('should have thrown');
      } on ReviewValidationFailure catch (e) {
        expect(e.fieldErrors['tags'], ['Unknown tag(s): foo']);
      }
    });

    test('404 → ReviewBookingNotFound', () async {
      when(() => remote.submitReview(
            bookingId: any(named: 'bookingId'),
            rating: any(named: 'rating'),
            tagKeys: any(named: 'tagKeys'),
            text: any(named: 'text'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 404, code: 'booking_not_found', message: '...',
        ),
      );
      expect(
        repo.submit(bookingId: 1, rating: 5, tagKeys: const [], text: ''),
        throwsA(isA<ReviewBookingNotFound>()),
      );
    });

    test('SocketException → ReviewNetworkFailure', () async {
      when(() => remote.submitReview(
            bookingId: any(named: 'bookingId'),
            rating: any(named: 'rating'),
            tagKeys: any(named: 'tagKeys'),
            text: any(named: 'text'),
          )).thenThrow(const SocketException('offline'));
      expect(
        repo.submit(bookingId: 1, rating: 5, tagKeys: const [], text: ''),
        throwsA(isA<ReviewNetworkFailure>()),
      );
    });

    test('unknown failure wraps message', () async {
      when(() => remote.submitReview(
            bookingId: any(named: 'bookingId'),
            rating: any(named: 'rating'),
            tagKeys: any(named: 'tagKeys'),
            text: any(named: 'text'),
          )).thenThrow(Exception('weird'));
      expect(
        repo.submit(bookingId: 1, rating: 5, tagKeys: const [], text: ''),
        throwsA(isA<UnknownReviewFailure>()),
      );
    });
  });
}
