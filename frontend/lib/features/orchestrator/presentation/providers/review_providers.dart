import 'package:riverpod_annotation/riverpod_annotation.dart';

// `eventHttpClientProvider` lives in the realtime feature's DI module;
// the orchestrator already reuses it (see this feature's own
// `dependency_injection.dart`). Importing directly here keeps the
// review providers grep-able as a self-contained unit.
import '../../../../core/realtime/presentation/providers/dependency_injection.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_form_state.dart';
import '../../domain/repositories/review_repository.dart';
import 'dependency_injection.dart';

part 'review_providers.g.dart';

// ─── Data sources + Repository (DI) ──────────────────────────────────────
//
// Kept in this dedicated file rather than scattered into
// dependency_injection.dart so the review feature stays self-contained:
// one grep for `review` finds everything that touches reviews.

@Riverpod(keepAlive: true)
IReviewRemoteDataSource reviewRemoteDataSource(Ref ref) =>
    ReviewRemoteDataSource(
      ref.watch(eventHttpClientProvider),
      ref.watch(orchestratorSecureStorageProvider),
    );

@Riverpod(keepAlive: true)
IReviewRepository reviewRepository(Ref ref) =>
    ReviewRepositoryImpl(remote: ref.watch(reviewRemoteDataSourceProvider));

// ─── Read: snapshot for a booking ─────────────────────────────────────
//
// Family keyed on booking id. `keepAlive: false` (default) — the
// snapshot is screen-scoped; navigating away from the booking
// orchestrator disposes the provider so the next visit re-fetches.
// If we ever want immediate re-render after a submit, callers
// `ref.invalidate(bookingReviewSnapshotProvider(bookingId))`.

@riverpod
Future<BookingReviewSnapshot> bookingReviewSnapshot(
  Ref ref,
  int bookingId,
) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getSnapshot(bookingId);
}

// ─── Write: in-progress form state ────────────────────────────────────
//
// Family keyed on booking id so two open bookings can each have their
// own draft state (unlikely in practice — the orchestrator screen is
// single-instance per route — but cheap and correct).
//
// Holds the rating + selected tag keys + text the user is composing.
// Reset implicitly when the user navigates away (notifier is disposed).

@riverpod
class ReviewFormNotifier extends _$ReviewFormNotifier {
  @override
  ReviewFormState build(int bookingId) {
    // Fresh form for every new mount. `bookingId` is the family key
    // and not used in the initial state itself.
    return const ReviewFormState();
  }

  void setRating(int rating) {
    // Defensive clamp — UI shouldn't send out-of-range but the
    // server's serializer rejects anything outside [1, 5] anyway.
    if (rating < 1 || rating > 5) return;
    // When the rating crosses the bucket boundary (≥4 vs ≤3), the
    // chip set the UI renders will flip — but selected keys from the
    // old bucket are no longer valid choices. Clear them to avoid
    // silently submitting stale keys the user can no longer see.
    final crossesBucket = state.rating != null &&
        ((state.rating! >= 4) != (rating >= 4));
    state = state.copyWith(
      rating: rating,
      selectedTagKeys: crossesBucket ? const <String>{} : state.selectedTagKeys,
    );
  }

  void toggleTag(String key) {
    final next = Set<String>.from(state.selectedTagKeys);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    state = state.copyWith(selectedTagKeys: next);
  }

  void setText(String text) {
    // Hard-cap matches the serializer's `max_length=500`. UI also
    // enforces via maxLength; this is defence-in-depth.
    final clipped = text.length > 500 ? text.substring(0, 500) : text;
    state = state.copyWith(text: clipped);
  }
}

// ─── Write: submission notifier ───────────────────────────────────────
//
// AsyncValue<Review?> — null when never submitted; AsyncData<Review>
// after success; AsyncError on failure. UI watches state to render
// loading spinner / disabled button / inline error.
//
// `submit` uses `AsyncValue.guard` as mandated by CLAUDE.md.

@riverpod
class ReviewSubmitNotifier extends _$ReviewSubmitNotifier {
  @override
  AsyncValue<Review?> build(int bookingId) {
    return const AsyncValue.data(null);
  }

  Future<void> submit({
    required int rating,
    required List<String> tagKeys,
    required String text,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(reviewRepositoryProvider);
      final review = await repo.submit(
        bookingId: bookingId,
        rating: rating,
        tagKeys: tagKeys,
        text: text,
      );
      // Invalidate the snapshot provider so the orchestrator screen
      // flips to the recap body on the next read.
      ref.invalidate(bookingReviewSnapshotProvider(bookingId));
      return review;
    });
  }
}
