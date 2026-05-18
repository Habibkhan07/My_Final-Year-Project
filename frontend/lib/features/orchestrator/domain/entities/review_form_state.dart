import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_form_state.freezed.dart';

/// In-progress, client-only state for the rating form.
///
/// Held by `reviewFormNotifier` (a Riverpod `keepAlive: false` family
/// keyed on `bookingId`). Persists for the lifetime of the booking-
/// orchestrator screen — disposed when the user navigates away, so
/// re-mounting starts fresh.
///
/// `selectedTagKeys` is a `Set<String>` (not `List`) because the UI
/// semantics are "multi-select toggleable chips" — order is presentation
/// (driven by [PredefinedTag] order), membership is state.
///
/// `rating` is nullable until the user taps a star. The submit button
/// renders disabled while rating is null — single source of truth for
/// the "can submit?" gate.
@freezed
abstract class ReviewFormState with _$ReviewFormState {
  const factory ReviewFormState({
    int? rating,
    @Default(<String>{}) Set<String> selectedTagKeys,
    @Default('') String text,
  }) = _ReviewFormState;

  const ReviewFormState._();

  /// True only when the user has picked at least one star. Drives the
  /// submit-button disabled state in [SubmitReviewButton].
  bool get canSubmit => rating != null;
}
