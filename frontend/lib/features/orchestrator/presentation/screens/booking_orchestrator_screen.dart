import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/booking_detail.dart';
import '../../domain/failures/booking_detail_failure.dart';
import '../providers/booking_detail_provider.dart';
import '../providers/booking_orchestrator_events_notifier.dart';
import '../providers/booking_rescheduled_notifier.dart';
import '../widgets/slots/body_slot.dart';
import '../widgets/slots/header_slot.dart';
import '../widgets/slots/primary_action_slot.dart';
import '../widgets/slots/secondary_actions_slot.dart';
import '../widgets/slots/timeline_slot.dart';

/// The full-screen orchestrator. One screen, every status, two roles.
///
/// **Slot layout (top to bottom):**
///   1. [HeaderSlot] — status label + counterparty name + tone tint.
///   2. [TimelineSlot] — phase progression dots.
///   3. [BodySlot] — exhaustive switch on status; renders the
///      appropriate stub/specialized body widget.
///   4. [SecondaryActionsSlot] — secondary text buttons.
///   5. [PrimaryActionSlot] — primary CTA button.
///
/// **Refresh UX.** During a realtime-event-driven refresh,
/// `detailAsync.isRefreshing && detailAsync.hasValue` is true; we
/// render a thin [LinearProgressIndicator] at the top and keep the
/// existing data visible underneath. No spinner flash, no scroll
/// position lost.
///
/// **Realtime hookup.** `initState` wakes the two screen-scoped
/// notifiers (events + rescheduled). They subscribe to
/// `systemEventProvider` and either invalidate the detail provider
/// (12 events) or pushReplacement to the child booking
/// (`bookingRescheduled`). They unmount when the screen pops.
class BookingOrchestratorScreen extends ConsumerWidget {
  const BookingOrchestratorScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CRITICAL: `ref.watch` (NOT `ref.read`) on the two screen-scoped
    // event notifiers. Both are `keepAlive: false`; `ref.read` does not
    // register as a Riverpod subscriber, so the providers would
    // auto-dispose on the next microtask after `initState` returned —
    // canceling their internal `ref.listen(systemEventProvider, …)` and
    // breaking the entire realtime-refresh chain. With `ref.watch`, the
    // providers stay alive for the screen's lifetime and dispose on pop.
    //
    // The notifiers return `void`; watching them never triggers a
    // rebuild because their state is identical to itself.
    ref.watch(bookingOrchestratorEventsProvider(jobId));
    ref.watch(bookingRescheduledProvider(jobId));

    final detailAsync = ref.watch(bookingDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #$jobId'),
      ),
      body: SafeArea(
        child: detailAsync.when(
          // Initial load — only fires when there's no prior data
          // (the .when callback unwraps the .isLoading + .hasValue
          // case to .data, so this handles first-mount only).
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            failure: error,
            onRetry: () =>
                ref.invalidate(bookingDetailProvider(jobId)),
          ),
          data: (booking) => _LoadedBody(
            booking: booking,
            isRefreshing: detailAsync.isRefreshing,
          ),
          // .skipLoadingOnRefresh defaults to true — when isRefreshing
          // is true with a prior value, we get the data callback (with
          // the stale value) and the thin top progress bar reflects the
          // in-flight refresh. `isRefreshing` (not `isLoading`) is the
          // semantically correct flag here: `isLoading` is also true
          // during initial load, but `_LoadedBody` only renders after
          // the first successful fetch, so they're behaviorally
          // equivalent today — using `isRefreshing` makes the intent
          // explicit and immune to future changes in `.when` semantics.
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.booking, required this.isRefreshing});

  final BookingDetail booking;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thin top progress bar during realtime-event refresh. Always
        // takes 2px of vertical space so the screen doesn't shift when
        // it appears/disappears.
        SizedBox(
          height: 2,
          child: isRefreshing ? const LinearProgressIndicator() : null,
        ),
        HeaderSlot(booking: booking),
        TimelineSlot(booking: booking),
        Expanded(
          child: SingleChildScrollView(
            child: BodySlot(booking: booking),
          ),
        ),
        SecondaryActionsSlot(booking: booking),
        PrimaryActionSlot(booking: booking),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.failure, required this.onRetry});

  final Object failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body) = _copy();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  (String, String) _copy() {
    final f = failure;
    if (f is BookingDetailNotFound) {
      return ('Not found', 'This booking does not exist.');
    }
    if (f is BookingDetailNotParticipant) {
      return ('Not allowed', 'You aren\'t a participant on this booking.');
    }
    if (f is BookingDetailOfflineNoCache) {
      return (
        'Offline',
        'You\'re offline and we don\'t have a cached copy of this booking yet. Try again when online.',
      );
    }
    if (f is BookingDetailNetworkFailure) {
      return ('Network error', 'Could not reach the server.');
    }
    if (f is BookingDetailServerFailure) {
      return ('Server error', 'Something went wrong on our end. Try again in a moment.');
    }
    return ('Error', 'Something went wrong.');
  }
}
