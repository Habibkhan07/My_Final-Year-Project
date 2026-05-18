import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/review.dart';
import '../../../domain/failures/review_failure.dart';
import '../../providers/review_providers.dart';
import '../_palette/orchestrator_palette.dart';
import 'booking_review_submitted_body.dart';
import 'optional_comment_field.dart';
import 'rating_stars_row.dart';
import 'submit_review_button.dart';

/// Top-level review surface mounted by the orchestrator screen's
/// COMPLETED / COMPLETED_INSPECTION_ONLY body stubs.
///
/// Renders one of three states:
/// - **Loading** — initial snapshot fetch in flight.
/// - **Recap** — `snapshot.review != null`. Static thank-you card.
/// - **Form** — `snapshot.review == null`. Stars + chips + comment +
///   submit button.
///
/// Error states use a compact inline error card with a retry CTA —
/// never blocks the rest of the COMPLETED body (receipt, etc.) from
/// rendering above this widget.
class BookingReviewBody extends ConsumerWidget {
  const BookingReviewBody({super.key, required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(bookingReviewSnapshotProvider(bookingId));
    return snapshotAsync.when(
      loading: () => const _ReviewLoadingShell(),
      error: (err, _) => _ReviewErrorShell(
        message: _humaniseFailure(err),
        onRetry: () =>
            ref.invalidate(bookingReviewSnapshotProvider(bookingId)),
      ),
      data: (snapshot) => snapshot.review != null
          ? BookingReviewSubmittedBody(review: snapshot.review!)
          : _ReviewFormShell(bookingId: bookingId, snapshot: snapshot),
    );
  }

  String _humaniseFailure(Object error) {
    // Keep error copy short per `feedback_short_ui_copy` memory (≤ 8
    // words for snackbars; this is a card so we can go a bit longer).
    if (error is ReviewBookingNotFound) return 'Booking not found.';
    if (error is ReviewUnauthorized) return 'Please sign in again.';
    if (error is ReviewNetworkFailure) return 'No connection — try again.';
    if (error is ReviewServerFailure) return 'Server hiccup — try again.';
    return 'Could not load review.';
  }
}

// ─── Form ─────────────────────────────────────────────────────────────

class _ReviewFormShell extends ConsumerWidget {
  const _ReviewFormShell({required this.bookingId, required this.snapshot});

  final int bookingId;
  final BookingReviewSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reviewFormProvider(bookingId));
    final formCtrl = ref.read(reviewFormProvider(bookingId).notifier);
    final submit = ref.watch(reviewSubmitProvider(bookingId));
    final submitCtrl = ref.read(reviewSubmitProvider(bookingId).notifier);

    // Surface submit errors as a snackbar (transient) rather than an
    // inline card — the form is still usable; the user can fix and
    // retry. `ref.listen` runs once per real transition, so we won't
    // re-snack on rebuilds.
    ref.listen<AsyncValue<Review?>>(
      reviewSubmitProvider(bookingId),
      (prev, next) {
        if (next is AsyncError) {
          final msg = _submitErrorCopy(next.error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    // Pick the chip bucket based on the rating the user has selected.
    // No rating → no chips (keeps the form minimal until the user
    // declares polarity).
    final chipSet = form.rating == null
        ? const <PredefinedTag>[]
        : (form.rating! >= 4
            ? snapshot.predefinedTags.positive
            : snapshot.predefinedTags.constructive);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How was your experience?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          RatingStarsRow(
            rating: form.rating,
            onChanged: formCtrl.setRating,
          ),

          if (form.rating != null) ...[
            const SizedBox(height: 16),
            Text(
              form.rating! >= 4 ? 'What made it great?' : 'What went wrong?',
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            // Wrapped chips. AnimatedSwitcher gives a soft cross-fade
            // when the bucket changes (4→3 stars or vice versa).
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<bool>(form.rating! >= 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: chipSet.map((tag) {
                      final selected =
                          form.selectedTagKeys.contains(tag.key);
                      return _InlineChip(
                        label: tag.label,
                        selected: selected,
                        onTap: () => formCtrl.toggleTag(tag.key),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OptionalCommentField(
              initialText: form.text,
              onChanged: formCtrl.setText,
            ),
          ],

          const SizedBox(height: 18),
          SubmitReviewButton(
            enabled: form.canSubmit,
            loading: submit.isLoading,
            onPressed: () => submitCtrl.submit(
              rating: form.rating!,
              tagKeys: form.selectedTagKeys.toList(),
              text: form.text,
            ),
          ),
        ],
      ),
    );
  }

  String _submitErrorCopy(Object? err) {
    // Short, action-focused copy per the user's `feedback_short_ui_copy`
    // memory: ≤ 8 words, state the missing requirement + action.
    if (err is ReviewAlreadySubmitted) return 'Already reviewed';
    if (err is ReviewNotEligible) return 'Job not complete yet';
    if (err is ReviewBookingNotFound) return 'Booking not found';
    if (err is ReviewUnauthorized) return 'Please sign in again';
    if (err is ReviewNetworkFailure) return 'No connection';
    if (err is ReviewServerFailure) return 'Server hiccup — try again';
    if (err is ReviewValidationFailure) return 'Check your entries';
    return 'Could not submit — try again';
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? OrchestratorPalette.brandPrimary
        : OrchestratorPalette.brandPrimaryTint06;
    final fg = selected ? Colors.white : OrchestratorPalette.brandPrimary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? OrchestratorPalette.brandPrimary
                  : OrchestratorPalette.brandPrimary.withValues(alpha: 0.24),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Loading + Error shells ───────────────────────────────────────────

class _ReviewLoadingShell extends StatelessWidget {
  const _ReviewLoadingShell();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor:
            AlwaysStoppedAnimation<Color>(OrchestratorPalette.brandPrimary),
      ),
    );
  }
}

class _ReviewErrorShell extends StatelessWidget {
  const _ReviewErrorShell({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900, fontSize: 13.5),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
