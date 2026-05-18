# Review Feature

Customer-side post-completion review of the technician. Mounted as a body of the **orchestrator screen** (`/booking/<id>`) when the booking is in `COMPLETED` or `COMPLETED_INSPECTION_ONLY` AND the viewer is the customer.

## UX summary

InDrive-style low-friction flow:

1. Tech marks job complete → backend fires `job_completed` event (high urgency) → customer's app auto-pushes `/booking/<id>` (foreground) or shows tray push (background; tap routes the same).
2. Customer lands on the COMPLETED body. Receipt sits at the top (unchanged); the review form sits below.
3. 5 tappable stars. Picking a star reveals the chip set (positive for ≥ 4 stars, constructive for ≤ 3). Optional comment field. Single brand-blue submit button.
4. On submit, the body flips to a thank-you recap with the submitted stars + chips + comment.
5. The submission also updates `TechnicianProfile.rating_average` + `TechnicianServicePerformance.rating_average` in the same DB transaction — matchmaking picks up the new score on the next dispatch with no extra wiring.

## Directory layout

```
features/orchestrator/
├── domain/
│   ├── entities/
│   │   ├── review.dart                     ← Review, PredefinedTag,
│   │   │                                     PredefinedTagBuckets,
│   │   │                                     BookingReviewSnapshot
│   │   └── review_form_state.dart          ← in-progress form draft
│   ├── failures/
│   │   └── review_failure.dart             ← sealed ReviewFailure hierarchy
│   └── repositories/
│       └── review_repository.dart          ← IReviewRepository contract
├── data/
│   ├── models/review_model.dart            ← wire models (Freezed + fromJson)
│   ├── mappers/review_mapper.dart          ← model → entity
│   ├── datasources/
│   │   └── review_remote_data_source.dart  ← http.Client GET/POST
│   └── repositories/
│       └── review_repository_impl.dart     ← HttpFailure → ReviewFailure
└── presentation/
    ├── providers/
    │   └── review_providers.dart           ← DI + 3 @riverpod providers
    └── widgets/review/
        ├── booking_review_body.dart        ← form / loading / error switch
        ├── booking_review_submitted_body.dart ← thank-you recap
        ├── rating_stars_row.dart           ← 5 tappable stars
        ├── tag_chips_grid.dart             ← multi-select chip wrap
        ├── optional_comment_field.dart     ← TextField with counter
        └── submit_review_button.dart       ← brand-blue CTA
```

## Domain entities

| Entity | Purpose | Backend source |
|---|---|---|
| `Review` | A submitted review row. | `Review` model serialized via `ReviewDetailSerializer`. |
| `PredefinedTag` | One chip — `{key, label}`. The `key` is persisted; `label` is display copy. | `_PredefinedTagSerializer`. |
| `PredefinedTagBuckets` | Both polarity buckets in one object. | `BookingReviewResponseSerializer.predefined_tags`. |
| `BookingReviewSnapshot` | GET response wrapper — `review` is null when not yet submitted. | `BookingReviewResponseSerializer`. |
| `ReviewFormState` | In-progress form draft (rating / selected chips / comment). | Client-only, not wired to backend. |

## Sealed failure hierarchy

`ReviewFailure` (sealed). Subclasses:

| Subclass | Backend trigger | UI affordance |
|---|---|---|
| `ReviewAlreadySubmitted` | 409 `review_already_submitted` | Snackbar "Already reviewed", screen refreshes to recap body. |
| `ReviewNotEligible` | 400 `review_not_eligible` | Snackbar "Job not complete yet". Carries `currentBookingStatus`. |
| `ReviewBookingNotFound` | 404 `booking_not_found` | Snackbar "Booking not found" — should not occur via normal nav. |
| `ReviewValidationFailure` | 400 `validation_error` | Snackbar "Check your entries". Carries `fieldErrors` map for per-field highlight. |
| `ReviewUnauthorized` | 401 | Snackbar "Please sign in again" — auth layer's interceptor handles the actual logout. |
| `ReviewNetworkFailure` | `SocketException` | Snackbar "No connection". Form remains usable. |
| `ReviewServerFailure` | 5xx | Snackbar "Server hiccup — try again". |
| `UnknownReviewFailure` | Anything else | Snackbar "Could not submit — try again". |

## Repository contract

`IReviewRepository` (`domain/repositories/review_repository.dart`):

| Method | Throws |
|---|---|
| `Future<BookingReviewSnapshot> getSnapshot(int bookingId)` | `ReviewBookingNotFound`, `ReviewUnauthorized`, `ReviewNetworkFailure`, `ReviewServerFailure`, `UnknownReviewFailure` |
| `Future<Review> submit({bookingId, rating, tagKeys, text})` | All of the above + `ReviewAlreadySubmitted`, `ReviewNotEligible`, `ReviewValidationFailure` |

The implementation lives in `data/repositories/review_repository_impl.dart`. Code-first error matching (branches on the backend's `code` before falling back to `statusCode`) so the wire contract is the source of truth, not HTTP semantics that could change.

## State (Riverpod)

Three `@riverpod` providers in `presentation/providers/review_providers.dart`:

| Provider | Type | Purpose |
|---|---|---|
| `bookingReviewSnapshotProvider(bookingId)` | `Future<BookingReviewSnapshot>` | Fetches the GET snapshot. Family per booking id. |
| `reviewFormProvider(bookingId)` | `ReviewFormState` (Notifier) | In-progress form state — rating / selected tags / comment text. Methods: `setRating`, `toggleTag`, `setText`. |
| `reviewSubmitProvider(bookingId)` | `AsyncValue<Review?>` (Notifier) | Submission state. `submit()` uses `AsyncValue.guard` per CLAUDE.md. On success, invalidates the snapshot provider so the UI flips to recap. |

Plus 2 DI providers (`keepAlive: true`):

| Provider | Type |
|---|---|
| `reviewRemoteDataSourceProvider` | `IReviewRemoteDataSource` |
| `reviewRepositoryProvider` | `IReviewRepository` |

## Data flow

### Read (mount)

```
BookingReviewBody widget mounts
        ↓
ref.watch(bookingReviewSnapshotProvider(bookingId))
        ↓
ReviewRepositoryImpl.getSnapshot
        ↓
ReviewRemoteDataSource.fetchSnapshot → GET /api/bookings/<id>/review/
        ↓
ReviewMapper.snapshotToDomain (model → entity)
        ↓
BookingReviewBody renders:
        ├── loading  → CircularProgressIndicator
        ├── error    → inline error card with Retry button
        └── data     → if snapshot.review != null: BookingReviewSubmittedBody
                       else:                       _ReviewFormShell
```

### Write (submit)

```
User taps Submit
        ↓
reviewSubmitProvider.notifier.submit(rating, tagKeys, text)
        ↓
state = AsyncLoading  (button shows spinner)
        ↓
AsyncValue.guard wraps:
        ReviewRepositoryImpl.submit
                ↓
        ReviewRemoteDataSource.submitReview → POST /api/bookings/<id>/review/
                ↓
        ReviewMapper.toDomain
        ↓
On success:
        state = AsyncData(Review)
        ref.invalidate(bookingReviewSnapshotProvider(bookingId))
                ↓
        Snapshot re-fetches; review != null → flip to recap body
On failure:
        state = AsyncError(ReviewFailure)
        ref.listen in widget surfaces a snackbar
```

## Offline + cache

No local cache layer. Reviews are infrequent single-shot writes; an offline-first cache adds complexity without proportional UX payoff. Network failure → typed `ReviewNetworkFailure` → user retries. (Booking-detail itself remains offline-first; only the review surface skips the cache.)

## Wire-in

`features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart`:

* `CompletedBodyStub` renders `BookingReviewBody(bookingId)` below the receipt **iff** `booking.viewerRole == BookingOrchestratorRole.customer`.
* `CompletedInspectionOnlyBodyStub` renders `BookingReviewBody(bookingId)` as the body content (no receipt — there was no quote).

The tech viewing their own completed job sees only the receipt — they're the rated party, not the rater.

## Visual

Brand-styled per the user's `feedback_ui_target_foodpanda` memory — visual identity is the existing booking-flow brand blue ElevatedButton language, NOT Foodpanda's orange. Foodpanda informs UX patterns (low friction, predefined chips) only.

```
┌────────────────────────────────────────┐
│  ← Booking complete                    │
├────────────────────────────────────────┤
│   [receipt card]                       │
│   [View receipt]                       │
│                                        │
│   How was your experience?             │
│      ★    ★    ★    ★    ★             │
│                                        │
│   What made it great?                  │
│   [On time] [Professional] [Clean]     │
│   [Quality work] [Polite] [Fair price] │
│                                        │
│   ┌──────────────────────────────┐     │
│   │ Anything else? (optional)    │     │
│   └──────────────────────────────┘     │
│                                        │
│   ┌──────────────────────────────┐     │
│   │       Submit review          │     │
│   └──────────────────────────────┘     │
└────────────────────────────────────────┘
```

When rating ≤ 3, chips swap (with a 220ms cross-fade) to constructive set: **Late · Messy · Rude · Overpriced · Incomplete work · Unsafe** and the prompt switches to "What went wrong?"

## Test inventory

```
test/features/orchestrator/
├── data/repositories/review_repository_impl_test.dart      (12 tests)
└── presentation/
    ├── providers/review_submit_notifier_test.dart           (4 tests)
    └── widgets/review/
        ├── rating_stars_row_test.dart                       (5 tests)
        └── tag_chips_grid_test.dart                         (4 tests)
```

Coverage:
- **Data layer**: full HTTP failure → typed-failure pipeline, sealed-class exhaustiveness.
- **State layer**: ProviderContainer + mock repository; loading → data / error transitions; post-success snapshot invalidation.
- **Widget layer**: hardcoded state injection; tap callbacks; visual rendering by state.

## Adding a new predefined tag

1. Append to `backend/technicians/constants/review_tags.py` (`POSITIVE_TAGS` or `CONSTRUCTIVE_TAGS`).
2. Restart Django/Celery.
3. The Flutter UI picks up the new chip on the next `GET /api/bookings/<id>/review/` call — **no app release required**.

The validation set `ALL_TAG_KEYS` rebuilds automatically from the two lists; the FE never hardcodes tag keys (always reads from the response).
