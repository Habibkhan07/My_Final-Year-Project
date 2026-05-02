import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/job_new_request.dart';
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
/// What the host still owns:
///
///   * The slide-up entrance and slide-down exit animation, gated on the
///     queue empty ↔ non-empty transitions. Animation duration is short on
///     purpose so the SLA timer is never visually obscured for long.
///   * The scrim (40% alpha at the single snap; tap does nothing — decline
///     must be an explicit action so a stray tap can't dismiss a high-payout
///     offer).
///   * Drag-down-to-dismiss. `DraggableScrollableSheet` stays — it's the
///     reason yesterday's discussion landed where it did. The technician can
///     swipe the sheet down to peek at what was behind it; releasing snaps
///     back to the single fixed fraction.
///   * A soft haptic when a new offer arrives while the sheet is already
///     showing. The card itself updates to the new head only when the current
///     head resolves (head-sticky principle); the haptic acknowledges that
///     more work is queued.
///   * Accept / decline routing to `removeRequest(jobId)`. Per `flag.md` #14
///     the remote acceptance endpoint is a future sprint — the host's
///     contract is "remove from queue" today, "POST + remove on success"
///     tomorrow.
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

  // ── Animation: slide-up entry, slide-down exit ──────────────────────────
  late final AnimationController _showController;
  late final Animation<double> _showCurve;

  // ── Sheet drag controller ───────────────────────────────────────────────
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  // ── State ───────────────────────────────────────────────────────────────
  bool _sheetMounted = false;

  /// Last non-empty queue. Retained during the slide-down exit animation so
  /// the sheet doesn't blank out before it has finished sliding off-screen.
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
    final prevLen = previous?.queue.length ?? 0;
    final nextLen = next.queue.length;

    if (prevLen == 0 && nextLen > 0) {
      // First arrival in an empty queue → mount + slide in.
      setState(() => _sheetMounted = true);
      _showController.forward(from: 0.0);
    } else if (prevLen > 0 && nextLen == 0) {
      // Queue emptied (head resolved, no successor) → slide out then unmount.
      _showController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _sheetMounted = false;
          _displayQueue = const [];
        });
      });
    } else if (nextLen > prevLen && _sheetMounted) {
      // New offer arrived while the sheet is already showing. The head-sticky
      // contract means the visible card does not swap — the new offer joins
      // the tail in priority order and will only become visible when the
      // current head resolves. The haptic acknowledges the queue grew.
      HapticFeedback.lightImpact();
    }
  }

  // ── Display ordering ────────────────────────────────────────────────────

  /// Returns the queue head-first by urgency (soonest expiry at index 0).
  ///
  /// Today the queue notifier is still FIFO append-only; this sort gives the
  /// technician the most-urgent offer at the head until the notifier rewrite
  /// in the next pass moves the priority logic into state. Once that lands
  /// this helper collapses to `queue` directly.
  List<JobNewRequest> _orderForRender(List<JobNewRequest> queue) {
    return [...queue]..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
  }

  // ── Action handlers ─────────────────────────────────────────────────────

  void _handleAccept(int jobId) {
    HapticFeedback.selectionClick();
    // TODO(accept-endpoint): wire to the bookings repository when the
    //   accept/decline endpoint lands. Until then, removeRequest is the
    //   only effect — see flag.md #14 (Accept button asymmetry).
    ref.read(incomingJobQueueProvider.notifier).removeRequest(jobId);
  }

  void _handleDecline(int jobId) {
    ref.read(incomingJobQueueProvider.notifier).removeRequest(jobId);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final liveQueue = ref.watch(incomingJobQueueProvider).queue;
    if (liveQueue.isNotEmpty) {
      // Refresh the retained snapshot whenever the queue is non-empty. The
      // snapshot survives the slide-down exit so the sheet body doesn't
      // blank out while sliding off-screen.
      _displayQueue = liveQueue;
    }

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
                final ordered = _orderForRender(_displayQueue);
                if (ordered.isEmpty) return const SizedBox.shrink();

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
                      queue: ordered,
                      onAccept: () => _handleAccept(ordered.first.jobId),
                      onDecline: () => _handleDecline(ordered.first.jobId),
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
