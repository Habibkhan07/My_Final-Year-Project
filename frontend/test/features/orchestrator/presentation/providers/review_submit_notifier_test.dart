// Tests for `ReviewSubmitNotifier` — the AsyncValue<Review?> notifier
// that wraps the submit call.
//
// CLAUDE.md state-layer convention: NEVER mount widgets. Use
// `ProviderContainer`, mock the repository, trigger the notifier
// method, assert state transitions (`AsyncLoading` → `AsyncData` /
// `AsyncError`).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/domain/entities/review.dart';
import 'package:frontend/features/orchestrator/domain/failures/review_failure.dart';
import 'package:frontend/features/orchestrator/domain/repositories/review_repository.dart';
import 'package:frontend/features/orchestrator/presentation/providers/review_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements IReviewRepository {}

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  Review makeReview({int id = 1}) => Review(
        id: id,
        rating: 5,
        tags: const ['on_time'],
        text: '',
        createdAt: DateTime.utc(2026, 5, 18, 10),
        reviewerName: 'Test U.',
      );

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [reviewRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('initial state is AsyncData(null)', () {
    final initial = container.read(reviewSubmitProvider(1));
    expect(initial, isA<AsyncData<Review?>>());
    expect(initial.value, isNull);
  });

  test('happy path: loading → data', () async {
    when(() => repo.submit(
          bookingId: 1, rating: 5,
          tagKeys: const ['on_time'], text: 'great',
        )).thenAnswer((_) async => makeReview());

    // Warm-up read so the notifier is built before we drive it.
    container.read(reviewSubmitProvider(1));

    final notifier = container.read(reviewSubmitProvider(1).notifier);
    final future = notifier.submit(
      rating: 5, tagKeys: const ['on_time'], text: 'great',
    );

    // After the call kicks off but before the await resolves, state
    // should be loading.
    expect(container.read(reviewSubmitProvider(1)), isA<AsyncLoading>());

    await future;
    final next = container.read(reviewSubmitProvider(1));
    expect(next, isA<AsyncData<Review?>>());
    expect(next.value!.rating, 5);
  });

  test('error path: loading → error', () async {
    when(() => repo.submit(
          bookingId: 1, rating: 5,
          tagKeys: const [], text: '',
        )).thenThrow(const ReviewAlreadySubmitted());

    container.read(reviewSubmitProvider(1));
    final notifier = container.read(reviewSubmitProvider(1).notifier);
    await notifier.submit(rating: 5, tagKeys: const [], text: '');

    final next = container.read(reviewSubmitProvider(1));
    expect(next, isA<AsyncError>());
    expect(next.error, isA<ReviewAlreadySubmitted>());
  });

  test('successful submit invalidates the snapshot provider', () async {
    when(() => repo.submit(
          bookingId: 1, rating: 4,
          tagKeys: const [], text: '',
        )).thenAnswer((_) async => makeReview());
    when(() => repo.getSnapshot(1)).thenAnswer(
      (_) async => BookingReviewSnapshot(
        review: null,
        predefinedTags: const PredefinedTagBuckets(
          positive: [], constructive: [],
        ),
      ),
    );

    // Prime the snapshot read (so there's something to invalidate).
    await container.read(bookingReviewSnapshotProvider(1).future);

    container.read(reviewSubmitProvider(1));
    final notifier = container.read(reviewSubmitProvider(1).notifier);

    // Second snapshot call should fire after invalidation.
    when(() => repo.getSnapshot(1)).thenAnswer(
      (_) async => BookingReviewSnapshot(
        review: makeReview(),
        predefinedTags: const PredefinedTagBuckets(
          positive: [], constructive: [],
        ),
      ),
    );

    await notifier.submit(rating: 4, tagKeys: const [], text: '');
    final refreshed = await container.read(
      bookingReviewSnapshotProvider(1).future,
    );

    // Snapshot now returns the review.
    expect(refreshed.review, isNotNull);
    // getSnapshot called twice: initial prime + post-invalidation re-fetch.
    verify(() => repo.getSnapshot(1)).called(2);
  });
}
