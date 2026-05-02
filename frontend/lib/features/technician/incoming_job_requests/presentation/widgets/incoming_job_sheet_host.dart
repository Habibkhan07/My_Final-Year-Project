import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/job_new_request.dart';
import '../providers/dependency_injection.dart';
import '../providers/incoming_job_queue_notifier.dart';
import '../providers/incoming_job_queue_state.dart';
import 'incoming_job_sheet.dart';

/// Global overlay that surfaces incoming job offers as a draggable bottom
/// sheet over whatever screen the technician is currently on.
///
/// **Serialized one-offer model.** The host shows ONLY the head of the queue.
/// There is no peek snap, no expanded snap, no focus-promotion affordance.
/// The technician sees one offer at a time — when the head resolves
/// (accept / decline / drain to zero), the next-most-urgent slides in. This
/// replaces the previous deck + peek + list UI which asked low-literacy users
/// to decode multiplicity (a "+N more" count, a stack of layered cards) — an
/// abstraction they didn't reliably interpret in field testing.
///
/// **Four cases the listener handles** (`_onQueueChanged`):
///
///   1. Empty → first arrival. Slide in.
///   2. Non-empty → empty (last offer resolved). Slide out, unmount.
///   3. Head changed (both states non-empty, `queue.first.jobId` differs).
///      Run the **vanish-reappear ceremony**: slide out → 250ms pause →
///      sound + heavy haptic → slide in with the new head. The pause and
///      audio cue make the new offer unmistakably *new* — without the
///      ceremony, the card content swap could be missed entirely if the
///      new request's service name resembles the previous one.
///   4. Head unchanged, tail grew. Soft haptic only — the visible card does
///      NOT swap (head-sticky principle); the haptic acknowledges that
///      more work is queued.
///
/// **Architectural note.** Presentation is driven entirely by the queue
/// notifier's state. `EventUrgencyRouter` does not push a route for
/// `jobNewRequest`; the queue subscriber and this overlay are the only
/// presentation surfaces.
class IncomingJobSheetHost extends ConsumerStatefulWidget {
  const IncomingJobSheetHost({super.key, required this.child});

  /// The GoRouter outlet (or any underlying app content). Sits underneath the
  /// scrim and the sheet.
  final Widget child;

  @override
  ConsumerState<IncomingJobSheetHost> createState() =>
      _IncomingJobSheetHostState();
}

class _IncomingJobSheetHostState extends ConsumerState<IncomingJobSheetHost>
    with SingleTickerProviderStateMixin {
  // Single snap fraction. The technician can drag below this (peek behind the
  // sheet) but on release the controller snaps back here.
  static const double _snapFraction = 0.68;

  /// Floor the user can drag the sheet down to. Above zero so a deliberate
  /// drag-down feels like "peek behind" rather than "dismiss" — accidental
  /// dismissal of a high-payout offer would be catastrophic UX.
  static const double _minDragFraction = 0.18;

  /// Time the swipe-to-accept widget needs for its confirm animation
  /// (thumb → right edge, "Accepted" check) before we start sliding the
  /// sheet out. If we removed the head from the queue too quickly, the
  /// user would see the slide-out begin before they could register that
  /// their swipe registered.
  static const Duration _acceptConfirmHold = Duration(milliseconds: 260);

  /// Pause between the slide-out and slide-in halves of the head-change
  /// ceremony. Long enough to read as "the sheet went away — something
  /// new is happening" rather than as a single slow swap.
  static const Duration _ceremonyPause = Duration(milliseconds: 250);

  // ── Animation: slide-up entry, slide-down exit ──────────────────────────
  late final AnimationController _showController;
  late final Animation<double> _showCurve;

  // ── Sheet drag controller ───────────────────────────────────────────────
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  // ── State ───────────────────────────────────────────────────────────────
  bool _sheetMounted = false;

  /// What the sheet is currently rendering. Managed *exclusively* by
  /// `_onQueueChanged` (and the ceremony method) — we deliberately do NOT
  /// mirror the live provider queue inside `build()` because that would
  /// swap the visible card content the moment the queue updates, robbing
  /// the slide-out half of the head-change ceremony of its reason to
  /// exist.
  List<JobNewRequest> _displayQueue = const [];

  ProviderSubscription<IncomingJobQueueState>? _subscription;

  @override
  void initState() {
    super.initState();
    _showController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _showCurve = CurvedAnimation(
      parent: _showController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _subscription = ref.listenManual<IncomingJobQueueState>(
      incomingJobQueueProvider,
      _onQueueChanged,
      // Don't fire for the initial empty state — only react to transitions.
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _draggableController.dispose();
    _showController.dispose();
    super.dispose();
  }

  // ── Queue change handler ────────────────────────────────────────────────

  void _onQueueChanged(
    IncomingJobQueueState? previous,
    IncomingJobQueueState next,
  ) {
    final prevHeadId = previous == null || previous.queue.isEmpty
        ? null
        : previous.queue.first.jobId;
    final nextHeadId =
        next.queue.isEmpty ? null : next.queue.first.jobId;

    // Case 1 — empty → first arrival.
    if (prevHeadId == null && nextHeadId != null) {
      setState(() {
        _displayQueue = next.queue;
        _sheetMounted = true;
      });
      _showController.forward(from: 0.0);
      return;
    }

    // Case 2 — non-empty → empty.
    if (prevHeadId != null && nextHeadId == null) {
      _showController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _sheetMounted = false;
          _displayQueue = const [];
        });
      });
      return;
    }

    // Case 3 — head changed; both states non-empty. Vanish-reappear ceremony.
    if (prevHeadId != null && nextHeadId != null && prevHeadId != nextHeadId) {
      // Pass the new queue snapshot in so the ceremony can swap content
      // silently (while the sheet is off-screen) without racing against
      // further state updates.
      unawaited(_runHeadChangeCeremony(List<JobNewRequest>.from(next.queue)));
      return;
    }

    // Case 4 — head unchanged. Tail-only change. Soft haptic if the queue
    // grew (a new offer just joined the tail); update _displayQueue silently
    // so future ceremonies see the latest snapshot.
    if (next.queue.length > (previous?.queue.length ?? 0) && _sheetMounted) {
      HapticFeedback.lightImpact();
    }
    setState(() => _displayQueue = next.queue);
  }

  /// The vanish-reappear ceremony: slide the sheet out, swap the rendered
  /// queue silently, pause briefly, fire the audio + haptic cue, and slide
  /// in with the new head visible.
  ///
  /// Total duration: ~220ms (slide out) + 250ms (pause) + 280ms (slide in) ≈
  /// 750ms. Add the 260ms swipe-confirm hold that precedes this from
  /// `_handleAccept`, and the full accept → next-offer ceremony lands at
  /// roughly 1 second — slow enough to register the change, fast enough not
  /// to feel like dead time.
  Future<void> _runHeadChangeCeremony(List<JobNewRequest> nextQueue) async {
    await _showController.reverse();
    if (!mounted) return;

    // Sheet is off-screen. Swap the rendered queue silently — the visible
    // card content updates while no one can see it, so the slide-in
    // surfaces the new head with no perceptible content flash.
    setState(() => _displayQueue = nextQueue);

    await Future<void>.delayed(_ceremonyPause);
    if (!mounted) return;

    // Audio cue + heavy haptic on slide-in. Redundant signals on purpose:
    // sound for a tech who's looking away, haptic for one who can't hear
    // it (silent mode, noisy environment), visual for one whose phone is
    // muted and in a pocket. Any one of the three reaches them.
    unawaited(
      ref.read(incomingJobSoundPlayerProvider).playNewOfferSound(),
    );
    HapticFeedback.heavyImpact();

    await _showController.forward(from: 0.0);
  }

  // ── Action handlers ─────────────────────────────────────────────────────
  //
  // No display-ordering helper — the queue notifier guarantees `queue.first`
  // is the head (locked once chosen, promoted by urgency on resolution).
  // The host renders the head directly; tail order is the notifier's
  // concern, not presentation's.

  void _handleAccept(int jobId) {
    HapticFeedback.selectionClick();
    // The swipe widget plays a confirm animation (thumb → right edge, then
    // morphs into a check) for ~260ms after the user releases past the
    // threshold. We hold removeRequest until the animation has played so
    // the user sees their swipe register before the sheet slides out. If
    // the host unmounts during the hold (route changes, app teardown), the
    // mounted check below short-circuits.
    Future<void>.delayed(_acceptConfirmHold, () {
      if (!mounted) return;
      // TODO(accept-endpoint): wire to the bookings repository when the
      //   accept/decline endpoint lands. Until then, removeRequest is the
      //   only effect — see flag.md #14 (Accept button asymmetry).
      ref.read(incomingJobQueueProvider.notifier).removeRequest(jobId);
    });
  }

  void _handleDecline(int jobId) {
    ref.read(incomingJobQueueProvider.notifier).removeRequest(jobId);
  }

  void _handleExpire(int jobId) {
    // Same end-state as decline (offer leaves the queue) — distinct only so
    // the host can wire different remote semantics later: decline will POST
    // /decline once that endpoint exists; expire will be a no-op because the
    // server's SLA-timeout Celery task fires authoritative.
    ref.read(incomingJobQueueProvider.notifier).removeRequest(jobId);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch the provider so this widget rebuilds on state transitions, but
    // don't read the queue directly here — `_displayQueue` is the source of
    // truth for what's rendered (managed by the listener so the slide-out
    // half of the ceremony renders the OLD head's data).
    ref.watch(incomingJobQueueProvider);

    return Stack(
      children: [
        widget.child,
        if (_sheetMounted) ...[
          // Scrim — fades in/out alongside the sheet, dims with the snap.
          FadeTransition(
            opacity: _showCurve,
            child: _SheetScrim(controller: _draggableController),
          ),
          // Sheet — slides up from below on entry, down on exit.
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_showCurve),
            child: AnimatedBuilder(
              animation: _draggableController,
              builder: (context, _) {
                final queue = _displayQueue;
                if (queue.isEmpty) return const SizedBox.shrink();
                final headId = queue.first.jobId;

                return DraggableScrollableSheet(
                  controller: _draggableController,
                  initialChildSize: _snapFraction,
                  minChildSize: _minDragFraction,
                  maxChildSize: _snapFraction,
                  snap: true,
                  // Single snap. Drag-down releases bounce back to the snap;
                  // there is no peek-snap or expanded-snap to land at.
                  snapSizes: const [_snapFraction],
                  builder: (context, scrollController) {
                    return IncomingJobSheet(
                      scrollController: scrollController,
                      queue: queue,
                      onAccept: () => _handleAccept(headId),
                      onDecline: () => _handleDecline(headId),
                      onExpire: () => _handleExpire(headId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Scrim ─────────────────────────────────────────────────────────────────

/// Backdrop scrim whose alpha tracks the sheet's snap fraction. With a single
/// snap the alpha is effectively constant at the snap; the controller-driven
/// computation is kept so a drag-down peek momentarily lifts the scrim,
/// revealing the underlying screen.
///
///   size ≤ 0.30 → α 0.00   (full peek-behind)
///   0.30..0.70  → α ramps 0.00 → 0.40
///   above 0.70  → α 0.40
///
/// Tapping the scrim does NOTHING — there's no `onTap` handler. The Container
/// absorbs taps when alpha is non-zero (so they don't reach the screen
/// underneath, which would feel weird with a half-screen scrim) but the
/// absence of a tap handler makes that absorption a no-op. Decline must be
/// an explicit button — accidentally dismissing a high-payout offer by tapping
/// the scrim would be catastrophic UX.
class _SheetScrim extends StatelessWidget {
  const _SheetScrim({required this.controller});
  final DraggableScrollableController controller;

  static double _alphaForSize(double size) {
    if (size <= 0.30) return 0.0;
    if (size <= 0.70) return ((size - 0.30) / 0.40) * 0.40;
    return 0.40;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final size = controller.isAttached ? controller.size : 0.0;
        final alpha = _alphaForSize(size);
        return IgnorePointer(
          ignoring: alpha < 0.02,
          child: Container(
            color: Colors.black.withValues(alpha: alpha),
          ),
        );
      },
    );
  }
}
