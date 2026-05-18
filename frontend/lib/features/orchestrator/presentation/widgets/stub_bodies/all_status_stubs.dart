// Per-status body widgets. Each renders a Foodpanda-style hero
// animation (`AnimatedStatusIcon`) plus the server-resolved `bodyText`
// prose inside a brand-blue `BodyShell` so every status reads as a
// cohesive elevated surface. EN_ROUTE and ARRIVED keep
// `LiveTrackingMap` because the map IS the experience while the tech
// is moving — the map's own ClipRRect surface replaces the shell on
// those phases.
//
// Dumb-UI principle (CLAUDE.md): every stub reads its prose from
// `booking.ui.bodyText`; none branches on status for copy.
import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/animations/loop_mode.dart';
import '../../../../../core/constants.dart';
import '../../../../../core/widgets/map/live_tracking_map.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../technician/dashboard/presentation/notifiers/technician_dashboard_notifier.dart';
import '../../../../technician/dashboard/presentation/widgets/tech_navigation_panel.dart';
import '../../../../technician/location_broadcaster/domain/entities/broadcast_state.dart';
import '../../../../technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart';
import '../../../../technician/location_broadcaster/presentation/widgets/broadcast_state_banner.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_orchestrator_role.dart';
import '../../../domain/entities/booking_quote.dart';
import '../../providers/technician_location_stream_notifier.dart';
import '../_palette/orchestrator_palette.dart';
import '../animated_status_icon.dart';
import '../meeting_countdown_button.dart';
import '../review/booking_review_body.dart';
import '../sheets/receipt_sheet.dart';
import '../slots/booking_summary_card.dart';
import '_body_shell.dart';

/// Audit H11 (W-8): resolves the call FAB number + tooltip for the
/// live-tracking map. Tech viewer dials the customer; customer viewer
/// dials configured support (no tech phone in the wire contract yet —
/// see flag #booking-detail-tech-phone). Returns `(phone: null, _)` to
/// suppress the FAB when no number is reachable (customer view in dev
/// where `--dart-define=SUPPORT_PHONE_NUMBER` was not passed).
///
/// [supportPhone] is a seam for tests (the compile-time constant from
/// `--dart-define` is otherwise un-overridable). Production callers
/// always use the default.
@visibleForTesting
({String? phone, String tooltip}) resolveLiveCallTarget(
  BookingDetail booking, {
  String supportPhone = AppConstants.supportPhoneNumber,
}) {
  final isTech = booking.viewerRole == BookingOrchestratorRole.technician;
  if (isTech) {
    return (phone: booking.customer.phoneNo, tooltip: 'Call customer');
  }
  if (supportPhone.isEmpty) return (phone: null, tooltip: 'Call');
  return (phone: supportPhone, tooltip: 'Call support');
}

// ─── Shared body layout — animated hero + bold message in shell ───────────

/// Standard non-map body. AnimatedStatusIcon hero on top, bold message
/// below pulled from `booking.ui.bodyText`. Wrapped in a [BodyShell] so
/// each status renders as a sibling of the [BookingSummaryCard] below
/// it (same white surface, brand-blue hairline, soft shadow).
class _AnimatedBody extends StatelessWidget {
  const _AnimatedBody({
    required this.status,
    required this.message,
    this.child,
  });

  final BookingStatus status;
  final String message;

  /// Optional widget rendered below the message — used by QUOTED for the
  /// quote line-item card.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BodyShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: AnimatedStatusIcon(status: status, size: 180)),
          const SizedBox(height: 22),
          // Dumb-UI principle: prose is server-driven (booking.ui.bodyText).
          // An empty bodyText is a deliberate server decision (some
          // terminal states communicate via the timeline pill alone) —
          // we render nothing in that case rather than reintroducing
          // status→copy logic on the frontend.
          if (message.isNotEmpty)
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: OrchestratorPalette.inkPrimary,
                height: 1.35,
              ),
            ),
          if (child != null) ...[const SizedBox(height: 20), child!],
        ],
      ),
    );
  }
}

// ─── WAITING archetype — slim body for always-waiting statuses ────────────

/// The "you can wait, nothing for you to do" body shape.
///
/// Replaces [_AnimatedBody]'s 180-px hero on the three statuses where
/// the user is passively waiting (AWAITING, INSPECTING, IN_PROGRESS).
/// Same [BodyShell] surface — preserves the brand-blue card family —
/// but the inner content shrinks to:
///
///   * A 40-px brand-blue breathing ring (replaces the dominating hero;
///     small enough to feel "background" rather than "stop and look").
///   * The server's [BookingDetail.ui.bodyText], centered, titleMedium.
///   * Optional live elapsed counter ("Working for X min" /
///     "Inspecting for X min") driven by a 30-second Timer.periodic
///     when [elapsedSince] is non-null.
///
/// The hero pill above (with its own pulsing dot) carries the status
/// fact; the body no longer competes for that attention. The audit's
/// Visual Sameness Catalog finding came from these three screens
/// rendering as identical "blue circle + giant icon + sentence" surfaces
/// — same shape, three statuses. After this widget lands they're still
/// visually similar (same shell + breathing ring), but the body's
/// vertical footprint shrinks by ~140 px and stops dominating the
/// screen.
class _WaitingBody extends StatefulWidget {
  const _WaitingBody({
    required this.message,
    this.elapsedSince,
    this.verbPrefix = '',
  });

  /// Server-resolved status prose. Empty string renders no text.
  final String message;

  /// When non-null, an elapsed-minutes counter renders beneath the
  /// message ("[verbPrefix] for X min"). Drives a 30-second ticker.
  final DateTime? elapsedSince;

  /// Verb that prefixes the elapsed counter, e.g. "Working", "Inspecting".
  /// Ignored when [elapsedSince] is null.
  final String verbPrefix;

  @override
  State<_WaitingBody> createState() => _WaitingBodyState();
}

class _WaitingBodyState extends State<_WaitingBody> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 30-second cadence is enough granularity for "Working for X min"
    // — second-level precision would over-render and second-by-second
    // updates have no UX value at the minute scale. Skipped in tests
    // via shouldLoopAnimations() (same pattern as every other animated
    // widget in this file).
    if (widget.elapsedSince != null && shouldLoopAnimations()) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant _WaitingBody old) {
    super.didUpdateWidget(old);
    // Re-arm or cancel the ticker if elapsedSince transitions
    // null↔non-null (e.g. when workStartedAt arrives on a WS frame).
    final wantsTicker =
        widget.elapsedSince != null && shouldLoopAnimations();
    final hasTicker = _ticker != null;
    if (wantsTicker && !hasTicker) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    } else if (!wantsTicker && hasTicker) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String? _elapsedLabel() {
    final since = widget.elapsedSince;
    if (since == null) return null;
    final minutes = DateTime.now().difference(since).inMinutes;
    if (minutes < 1) return '${widget.verbPrefix} · just started';
    return '${widget.verbPrefix} for $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _elapsedLabel();
    // Column uses `CrossAxisAlignment.stretch` so it fills the card's
    // horizontal width (otherwise the Column shrink-wraps to its
    // widest child's intrinsic width and the radar visually anchors
    // to the card's left edge, not the center). The ring is then
    // wrapped in `Center()` to sit horizontally centered inside the
    // stretched column. Mirrors the existing `_AnimatedBody`
    // centering recipe.
    return BodyShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _BreathingRing()),
          if (widget.message.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: OrchestratorPalette.inkPrimary,
                height: 1.35,
              ),
            ),
          ],
          if (label != null) ...[
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: OrchestratorPalette.inkSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centered radar-style animation for the WAITING archetype.
///
/// 96 px outer envelope by default. Three concentric brand-blue rings
/// expand outward and fade at staggered phases (0.0, 0.33, 0.66 of a
/// single 2.4 s cycle) — reads as "the system is alive and watching"
/// without the dominance of the dropped 180-px hero. A 28-px solid
/// brand-blue dot stays in the center as the visual anchor, with a
/// soft brand-blue drop shadow that pairs with the rest of the
/// orchestrator's surface family.
///
/// **Why a radar pattern, not a single breathing halo.** The previous
/// 40-px version of this widget (one halo + a 13-px solid dot)
/// rendered as "almost nothing" on a real device — the dot was small,
/// the halo was faint, and the eye skipped past it. Multiple rings
/// expanding outward give the animation enough visual weight to
/// anchor the center of the WAITING card without competing with the
/// hero header above.
///
/// Single AnimationController, no Opacity widgets (color alphas only)
/// — cheap to mount.
class _BreathingRing extends StatefulWidget {
  const _BreathingRing();

  /// Outer envelope. Inlined here — every caller renders the WAITING
  /// archetype card at the same scale, so a configurable size would
  /// be premature abstraction (per CLAUDE.md).
  static const double _envelope = 96;

  @override
  State<_BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<_BreathingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (shouldLoopAnimations()) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Ring at the given phase offset [0, 1). Each ring scales from 35%
  /// → 100% of the envelope while fading from peak alpha → 0,
  /// producing a single radar ping per cycle. Three rings at
  /// staggered phases keep at least one ring visible at all times.
  Widget _ring(double phase, double t) {
    final p = (t + phase) % 1.0;
    final scale = 0.35 + p * 0.65;
    final alpha = (1.0 - p) * 0.30;
    return Container(
      width: _BreathingRing._envelope * scale,
      height: _BreathingRing._envelope * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: OrchestratorPalette.brandPrimary.withValues(alpha: alpha),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        return SizedBox(
          width: _BreathingRing._envelope,
          height: _BreathingRing._envelope,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(0.0, t),
              _ring(0.33, t),
              _ring(0.66, t),
              // Center solid dot — fixed size (independent of the
              // envelope) so the anchor reads the same across any
              // future caller that supplies a different `size`.
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OrchestratorPalette.brandPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: OrchestratorPalette.brandPrimary
                          .withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Per-status stubs ─────────────────────────────────────────────────────

class AwaitingBodyStub extends StatelessWidget {
  const AwaitingBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _WaitingBody(
    message: booking.ui.bodyText,
  );
}

/// CONFIRMED body, role-aware + up-next-aware.
///
/// **Tech viewer + this booking is the dashboard's up-next** — render the
/// shared [TechNavigationPanel] (static map + Start Navigation + Call).
/// The orchestrator's existing PrimaryActionSlot still surfaces the
/// "I'm on my way" button below; Start Navigation is the external Maps
/// launcher (different verb).
///
/// **All other cases** — customer viewing CONFIRMED, OR tech viewing a
/// later-today job that isn't the imminent one — render the plain
/// "Technician confirmed your booking" hero. The tech doesn't get a
/// shortcut to navigate to a job they have a closer visit before.
class ConfirmedBodyStub extends ConsumerWidget {
  const ConfirmedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addr = booking.address;
    final isTech = booking.viewerRole == BookingOrchestratorRole.technician;

    bool isUpNext = false;
    if (isTech && addr != null) {
      // Dashboard provider auto-fetches at login per realtimeBootHooks;
      // by the time the tech opens the orchestrator it's cached. If for
      // any reason it isn't resolved, fall back to the plain body —
      // worst case the tech misses the shortcut on this one screen.
      final dash = ref.watch(technicianDashboardProvider);
      isUpNext = dash.value?.dashboard.upNextJob?.jobId == booking.id;
    }

    if (isTech && isUpNext && addr != null) {
      return BodyShell(
        child: TechNavigationPanel(
          destLat: addr.latitude,
          destLng: addr.longitude,
          bookingId: booking.id,
          // Pass the server-emitted action (PrimaryActionSlot suppresses
          // it for this case, but the server is still the source of
          // truth for the endpoint + method + label). On the tech
          // CONFIRMED screen the primary action is "I'm on my way" →
          // /en-route/; we route it through the panel.
          flipAction: booking.ui.primaryAction,
          mapHeight: 200,
        ),
      );
    }

    return _AnimatedBody(
      status: BookingStatus.confirmed,
      message: booking.ui.bodyText,
    );
  }
}

/// Customer / tech viewing a booking that is EN_ROUTE.
///
/// Map fills the body — it IS the experience while the tech is on the
/// move. The booking's UI prose ("Tech will reach you in a few minutes")
/// sits below as supporting text.
///
/// **P-PAN audit (Tier 2):** the stub is a `StatelessWidget` so it does
/// NOT rebuild on every ~5s GPS frame or on every broadcast-state
/// transition. The provider watches live inside two `ConsumerWidget`
/// leaves ([_EnRouteBroadcastBanner], [_EnRouteMapLeaf]) so only those
/// subtrees rebuild when their respective providers emit. Pre-fix the
/// stub itself watched both providers, so every frame rebuilt the
/// Padding / LayoutBuilder / Column / banner / mapWrapper / bodyText
/// chain — cascading into `LiveTrackingMap.didUpdateWidget` and adding
/// rebuild pressure on top of the platform-view gesture thread.
class EnRouteBodyStub extends StatelessWidget {
  const EnRouteBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final addr = booking.address;
    if (addr == null) {
      // Defensive — backend always serializes address for non-terminal
      // bookings, but the contract allows null. Fall back to the
      // animated hero rather than rendering a map with a default centre.
      return _AnimatedBody(
        status: BookingStatus.enRoute,
        message: booking.ui.bodyText,
      );
    }
    final destination = LatLng(addr.latitude, addr.longitude);
    final isTech = booking.viewerRole == BookingOrchestratorRole.technician;
    final callTarget = resolveLiveCallTarget(booking);

    final banner = _EnRouteBroadcastBanner(
      bookingId: booking.id,
      isTech: isTech,
    );
    final mapWrapper = _EnRouteMapLeaf(
      bookingId: booking.id,
      destination: destination,
      callTarget: callTarget,
      viewerIsTechnician: isTech,
    );
    final bodyText = Text(
      booking.ui.bodyText,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: OrchestratorPalette.inkSecondary,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      // P3 audit fix (Tier 2): the screen no longer wraps map-led
      // statuses in SingleChildScrollView (the parent ScrollView was
      // stealing single-finger vertical drag from the map, which is
      // unfixable on flutter_map — no `gestureRecognizers` API).
      // LayoutBuilder lets the stub adapt:
      //   - Bounded vertical constraints (customer EN_ROUTE — screen
      //     wraps in Expanded): use `Expanded(child: map)` so the
      //     map fills available space. The map widget claims all
      //     gestures because no ScrollView is competing.
      //   - Unbounded constraints (tech EN_ROUTE — screen still wraps
      //     in SingleChildScrollView so the tech can scroll past the
      //     map to the supporting text): keep the previous SizedBox
      //     layout (Expanded inside a ScrollView throws). The map
      //     still uses the EagerGestureRecognizer (Google) / widened
      //     InteractiveFlag set (OSM) to claim what it can.
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight.isFinite) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                banner,
                Expanded(child: mapWrapper),
                const SizedBox(height: 12),
                bodyText,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              banner,
              SizedBox(
                height: (MediaQuery.of(context).size.height * 0.70).clamp(
                  420.0,
                  640.0,
                ),
                child: mapWrapper,
              ),
              const SizedBox(height: 12),
              bodyText,
            ],
          );
        },
      ),
    );
  }
}

/// Leaf widget that owns the `technicianLocationStreamProvider` watch
/// for EN_ROUTE. Isolates the ~5s GPS-frame rebuild to the map subtree
/// only — the surrounding stub (banner, body text, layout chrome) is
/// pure stateless content and stays put.
class _EnRouteMapLeaf extends ConsumerWidget {
  const _EnRouteMapLeaf({
    required this.bookingId,
    required this.destination,
    required this.callTarget,
    required this.viewerIsTechnician,
  });

  final int bookingId;
  final LatLng destination;
  final ({String? phone, String tooltip}) callTarget;

  /// Forwarded to `LiveTrackingMap` so the no-frame-yet pill renders
  /// tech-self copy ("Acquiring GPS fix…") instead of customer copy
  /// ("Waiting for technician's location…"). Source-of-truth is
  /// `EnRouteBodyStub.isTech`.
  final bool viewerIsTechnician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frame = ref.watch(technicianLocationStreamProvider(bookingId));
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LiveTrackingMap(
        technicianPosition: frame == null
            ? null
            : LatLng(frame.latitude, frame.longitude),
        technicianHeadingDegrees: frame?.heading,
        lastFrameAt: frame?.frameArrivedAt,
        // P2: surface GPS accuracy so LiveTrackingMap can render
        // the Foodpanda-style uncertainty ring.
        accuracyMeters: frame?.accuracyMeters,
        destination: destination,
        phase: TrackingPhase.enRoute,
        callPhoneNumber: callTarget.phone,
        callTooltip: callTarget.tooltip,
        viewerIsTechnician: viewerIsTechnician,
      ),
    );
  }
}

/// Leaf widget that owns the `foregroundLocationServiceControllerProvider`
/// watch for EN_ROUTE. Tech-only — customer view skips the provider read
/// entirely and renders an idle-state banner. Isolating this watch keeps
/// permission/lifecycle transitions from rebuilding the stub's map subtree.
///
/// Audit C6: surface non-running BroadcastState to the tech so they
/// know their location is NOT being shared.
class _EnRouteBroadcastBanner extends ConsumerWidget {
  const _EnRouteBroadcastBanner({
    required this.bookingId,
    required this.isTech,
  });

  final int bookingId;
  final bool isTech;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastState = isTech
        ? ref.watch(foregroundLocationServiceControllerProvider(bookingId))
        : BroadcastState.idle;
    return BroadcastStateBanner(
      state: broadcastState,
      onOpenSettings: isTech
          ? () => ref
                .read(
                  foregroundLocationServiceControllerProvider(
                    bookingId,
                  ).notifier,
                )
                .openSystemSettings()
          : null,
    );
  }
}

/// ARRIVED state — InDrive-style meeting flow.
///
/// Pakistani urban context: techs do NOT knock the door. They park at
/// the address pin and the customer walks out to find them. This stub
/// surfaces the meeting as a high-urgency "go outside now" experience.
///
/// **Customer view (Foodpanda-style, map-led):**
///   * Body order: live map (large, top — the visual anchor) → address
///     recap → [BookingSummaryCard] (scroll-revealed at the bottom of
///     the scrollable body). The body has NO hero shell with text +
///     countdown because both have been merged into the pinned
///     [ArrivalActionCard] that lives in the action bar. This avoids
///     splitting the customer's attention across the map (message
///     above / button below).
///   * The summary card normally pinned above the action bar is
///     suppressed by [BookingOrchestratorScreen] on customer-ARRIVED
///     so it can be re-rendered here at the scroll bottom — the call
///     affordance ("can't find the tech outside") stays one scroll
///     away, but doesn't compete with the action moment.
///
/// **Tech view (unchanged):**
///   * `BodyShell` hosting: animated arrival hero + bold "you're at the
///     address" copy + read-only [MeetingCountdownButton.readOnly]
///     mirroring the customer's window. On customer-ack the mirror
///     swaps to an [_AckConfirmationChip] (brand-cool green).
///   * Address recap.
///   * No live map on tech-side — the tech IS at the address; rendering
///     a map of themselves adds noise without information.
class ArrivedBodyStub extends ConsumerWidget {
  const ArrivedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  /// 5 minutes mirrors the InDrive arrival-wait window. The tech retains
  /// the existing no-show path after expiry; this script does NOT
  /// auto-cancel (per `project_arrived_meeting_ux` memory — expiry is
  /// social pressure on the customer, the tech decides what to do next).
  static const _meetingWindow = Duration(minutes: 5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTech = booking.viewerRole == BookingOrchestratorRole.technician;
    return isTech
        ? _TechArrivedBody(booking: booking, meetingWindow: _meetingWindow)
        : _CustomerArrivedBody(booking: booking);
  }
}

/// Customer-side ARRIVED layout — map-only (Foodpanda position).
///
/// **The body is the map. Nothing else.**
///
/// Map slot — LARGE (~70% of screen, clamped 420–640px). The map IS
/// the focal element; the customer's job in this moment is "find the
/// tech outside", and the map answers that.
///
/// **No address recap card.** The pin shows where the meeting
/// happens; rendering the address text below the pin duplicates the
/// same fact in two places.
///
/// **No BookingSummaryCard.** Tech identity is built during
/// CONFIRMED + EN_ROUTE; resurfacing it during ARRIVED competes with
/// the urgency moment (the pinned countdown) for no information
/// value. The map's own Call FAB handles the "I can't find them
/// outside" case (`callPhoneNumber` is wired to support for the
/// customer view via `resolveLiveCallTarget`).
///
/// The screen's always-on summary slot is suppressed for customer
/// ARRIVED (`booking_orchestrator_screen.dart`'s `hideAlwaysOnSummary`),
/// so dropping it from the body removes the summary card from ARRIVED
/// entirely (apart from the defensive null-address fallback below).
///
/// The "Your technician has arrived" message + "I'm coming out"
/// countdown button live in the pinned [ArrivalActionCard] at the
/// bottom of the screen (inside the action bar) — see
/// `arrival_action_card.dart` for the rationale.
/// **P-PAN audit (Tier 2):** stateless shell. The 5s GPS-frame watch
/// lives in [_CustomerArrivedMapLeaf] so the surrounding Padding /
/// LayoutBuilder doesn't repaint on every frame.
class _CustomerArrivedBody extends StatelessWidget {
  const _CustomerArrivedBody({required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final addr = booking.address;

    // Defensive — backend always serializes address for non-terminal
    // bookings. If it ever ships null, fall back to a recap-less view
    // rather than a map centred on (0, 0).
    if (addr == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: BookingSummaryCard(booking: booking),
      );
    }

    final destination = LatLng(addr.latitude, addr.longitude);
    final callTarget = resolveLiveCallTarget(booking);

    // Body on customer ARRIVED is the map, full stop.
    //
    //   * No address recap card — the map pin already shows where
    //     the customer is meeting the tech; rendering the address
    //     text below the pin duplicates the same fact in two places.
    //
    //   * No BookingSummaryCard — tech identity is built during
    //     CONFIRMED + EN_ROUTE; resurfacing it during ARRIVED
    //     competes with the urgency moment (the pinned countdown
    //     in ArrivalActionCard) for no information value. The
    //     map's own Call FAB (configured via callPhoneNumber) is
    //     the affordance for "I can't find them outside."
    //
    // The screen's always-on summary slot remains suppressed for
    // customer-ARRIVED (booking_orchestrator_screen.dart's
    // `hideAlwaysOnSummary`), so dropping it from the body removes
    // the summary card from ARRIVED entirely.
    final mapWrapper = _CustomerArrivedMapLeaf(
      bookingId: booking.id,
      destination: destination,
      callTarget: callTarget,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      // P3 audit fix (Tier 2): adapt to bounded vs unbounded vertical
      // constraints. See the matching block in EnRouteBodyStub for
      // rationale. Customer-ARRIVED is always map-led, so in
      // production this is the Expanded branch — but tests mount the
      // body in a Scaffold which provides bounded constraints too, so
      // both paths exercise.
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight.isFinite) {
            return SizedBox.expand(child: mapWrapper);
          }
          return SizedBox(
            height: (MediaQuery.of(context).size.height * 0.70).clamp(
              420.0,
              640.0,
            ),
            child: mapWrapper,
          );
        },
      ),
    );
  }
}

/// Leaf widget that owns the `technicianLocationStreamProvider` watch
/// for customer-ARRIVED. Mirror of [_EnRouteMapLeaf] with the
/// `TrackingPhase.arrived` switch and no banner. Kept as a separate
/// class (rather than a parameterised leaf) because the two phases
/// differ in both the LiveTrackingMap arg AND the parent layout
/// (EN_ROUTE has banner + bodyText siblings; ARRIVED is map-only).
class _CustomerArrivedMapLeaf extends ConsumerWidget {
  const _CustomerArrivedMapLeaf({
    required this.bookingId,
    required this.destination,
    required this.callTarget,
  });

  final int bookingId;
  final LatLng destination;
  final ({String? phone, String tooltip}) callTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frame = ref.watch(technicianLocationStreamProvider(bookingId));
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LiveTrackingMap(
        technicianPosition: frame == null
            ? null
            : LatLng(frame.latitude, frame.longitude),
        technicianHeadingDegrees: frame?.heading,
        lastFrameAt: frame?.frameArrivedAt,
        accuracyMeters: frame?.accuracyMeters,
        destination: destination,
        phase: TrackingPhase.arrived,
        callPhoneNumber: callTarget.phone,
        callTooltip: callTarget.tooltip,
      ),
    );
  }
}

/// Tech-side ARRIVED layout — preserved from the previous design.
///
/// The tech is parked AT the customer's address; rendering a map of
/// themselves adds noise. Instead, the BodyShell hosts the animated
/// hero + bold copy + a read-only countdown mirror so the tech knows
/// how long they've been waiting and when the customer has ack'd. The
/// permission banner sits above the shell so it isn't clipped by the
/// shell's clipBehavior.
class _TechArrivedBody extends ConsumerWidget {
  const _TechArrivedBody({
    required this.booking,
    required this.meetingWindow,
  });

  final BookingDetail booking;
  final Duration meetingWindow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrivedAt = booking.phaseTimestamps.arrivedAt;
    final ackedAt = booking.phaseTimestamps.customerAcknowledgedArrivalAt;
    final addr = booking.address;

    final shellChildren = <Widget>[
      Center(
        child: AnimatedStatusIcon(status: BookingStatus.arrived, size: 140),
      ),
      const SizedBox(height: 16),
      if (booking.ui.bodyText.isNotEmpty)
        Text(
          booking.ui.bodyText,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: OrchestratorPalette.inkPrimary,
                height: 1.35,
              ),
        ),
    ];

    if (ackedAt != null) {
      shellChildren.add(const SizedBox(height: 16));
      shellChildren.add(_AckConfirmationChip(ackedAt: ackedAt));
    } else if (arrivedAt != null) {
      shellChildren.add(const SizedBox(height: 16));
      shellChildren.add(MeetingCountdownButton.readOnly(
        arrivedAt: arrivedAt,
        label: 'Customer notified',
        expiredLabel: 'Customer is overdue',
        icon: Icons.person_pin_circle_rounded,
        meetingWindow: meetingWindow,
      ));
    }

    final broadcastState =
        ref.watch(foregroundLocationServiceControllerProvider(booking.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: BroadcastStateBanner(
            state: broadcastState,
            onOpenSettings: () => ref
                .read(
                  foregroundLocationServiceControllerProvider(booking.id)
                      .notifier,
                )
                .openSystemSettings(),
          ),
        ),
        BodyShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: shellChildren,
          ),
        ),
        if (addr != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _AddressRecapCard(addressText: addr.addressText),
          ),
      ],
    );
  }
}

/// On-brand "Customer is coming out" chip on the tech side after the
/// customer acks. Static — no ticker — because the only thing that
/// would change is the relative time, and "just now" is fine here.
/// Retoned from stock Material green to the cool successDeep / successSurface
/// pair so it sits in the same hue family as the brand blue.
class _AckConfirmationChip extends StatelessWidget {
  const _AckConfirmationChip({required this.ackedAt});
  final DateTime ackedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: OrchestratorPalette.successSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OrchestratorPalette.successDeep.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: OrchestratorPalette.successDeep.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OrchestratorPalette.successDeep,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: OrchestratorPalette.successDeep.withValues(alpha: 0.32),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer is coming out',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: OrchestratorPalette.successDeep,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "They've acknowledged your arrival.",
                  style: TextStyle(
                    fontSize: 12,
                    color: OrchestratorPalette.successDeep.withValues(
                      alpha: 0.85,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Address recap card. Matches the BookingSummaryCard's surface
/// language — white background, brand-blue hairline border, soft brand
/// shadow — so the ARRIVED screen reads as ONE surface family rather
/// than the previous grey/white mix.
class _AddressRecapCard extends StatelessWidget {
  const _AddressRecapCard({required this.addressText});
  final String addressText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.10),
        ),
        boxShadow: OrchestratorPalette.brandSoftShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OrchestratorPalette.brandPrimaryTint12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: OrchestratorPalette.brandPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meeting point',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: OrchestratorPalette.inkTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  addressText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: OrchestratorPalette.inkPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InspectingBodyStub extends StatelessWidget {
  const InspectingBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _WaitingBody(
    message: booking.ui.bodyText,
    // arrivedAt is the closest available anchor — true
    // inspectionStartedAt isn't always serialized to the wire. The
    // tech transitions ARRIVED → INSPECTING within seconds of tapping
    // Start inspection, so the gap is small enough to be honest.
    elapsedSince: booking.phaseTimestamps.arrivedAt,
    verbPrefix: 'Inspecting',
  );
}

/// QUOTED state.
///
/// **Body is the quote card. No decorative hero.**
///
/// Previously this stub rendered through `_AnimatedBody`, which
/// stacked a 180-px receipt icon + the server's instructional
/// bodyText sentence ABOVE the actual quote card. Two receipt
/// visuals stacked + an "approve, decline, or ask for a revision"
/// sentence that duplicates the action buttons below. The customer
/// had to scroll past the decorative hero to reach the prices that
/// they came to read.
///
/// The body now surfaces [QuoteSummaryCard] immediately. The action
/// area below (Decline / Negotiate price / Approve) is the only
/// instructional surface needed.
///
/// **Customer view — post-arrival, face-to-face.** In this market
/// the customer and technician are physically together from the
/// moment the tech arrives. The customer reads the line items with
/// the tech standing right there. Actions:
///   * **Approve** — primary, solid brand-blue.
///   * **Decline** — secondary, outlined; surfaced via the
///     destructive-filter carve-out in [SecondaryActionsSlot].
///   * **Negotiate price** — secondary, outlined; only present when
///     there's labor on the bill (server omits the action otherwise).
///
/// On customer-QUOTED the screen suppresses the always-on summary
/// slot ([BookingOrchestratorScreen]'s `hideAlwaysOnSummary`) and
/// this stub re-mounts the [BookingSummaryCard] at the scroll
/// bottom — the call affordance stays one scroll away for the rare
/// follow-up after the tech has left.
///
/// **Tech view.** Tech is the quote author here, watching for the
/// customer's decision. Surface the same [QuoteSummaryCard] so the
/// tech sees what the customer is looking at — the prices they
/// sent — at a glance. Their tech-info card stays in its always-on
/// slot above the action bar (rendered by the screen).
///
/// **Null-quote fallback.** When `activeQuote` is null on QUOTED
/// (defensive — backend always stamps a quote before this status,
/// so this shouldn't fire), the body falls back to a slim
/// [BodyShell] with the server's bodyText. No icon hero in either
/// path.
class QuotedBodyStub extends StatelessWidget {
  const QuotedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final quote = booking.activeQuote;
    final isCustomerView =
        booking.viewerRole == BookingOrchestratorRole.customer;

    final Widget quoteSurface = quote == null
        ? _NullQuoteFallback(message: booking.ui.bodyText)
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: QuoteSummaryCard(quote: quote),
          );

    if (!isCustomerView) return quoteSurface;

    // Customer keeps the scroll-revealed BookingSummaryCard at the
    // bottom — the call affordance is one scroll away. The screen's
    // always-on summary slot is suppressed for customer-QUOTED so
    // this is the only mount point.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quoteSurface,
        BookingSummaryCard(booking: booking),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Defensive shell for the unlikely case where status is QUOTED but
/// `activeQuote` is null. Renders bodyText inside a minimal
/// [BodyShell] — no icon hero, just enough surface to make the empty
/// state legible. Backend stamps a quote before flipping status, so
/// this should never render in practice.
class _NullQuoteFallback extends StatelessWidget {
  const _NullQuoteFallback({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = message.isEmpty ? 'Your quote is being prepared.' : message;
    return BodyShell(
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: OrchestratorPalette.inkPrimary,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class InProgressBodyStub extends StatelessWidget {
  const InProgressBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _WaitingBody(
    message: booking.ui.bodyText,
    elapsedSince: booking.phaseTimestamps.workStartedAt,
    verbPrefix: 'Working',
  );
}

class CompletedBodyStub extends StatelessWidget {
  const CompletedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final quote = booking.activeQuote;
    // Customer-only: the review surface mounts under the receipt. The
    // tech viewing their own completed job sees only the receipt — they
    // are the rated party, not the rater.
    final showReview = booking.viewerRole == BookingOrchestratorRole.customer;

    return _AnimatedBody(
      status: BookingStatus.completed,
      message: booking.ui.bodyText,
      // Inline receipt stays — users who scroll see it as before.
      // The "View receipt" button below adds a one-tap focused entry
      // point for the cash-paying customer who wants to screenshot
      // the receipt for WhatsApp / records (see ReceiptSheet docstring).
      // When activeQuote is null (inspection-only completion / edge
      // case) both the card and the button are suppressed.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (quote != null) ...[
            QuoteSummaryCard(quote: quote),
            const SizedBox(height: 12),
            _ViewReceiptButton(quote: quote),
          ],
          if (showReview) ...[
            if (quote != null) const SizedBox(height: 16),
            BookingReviewBody(bookingId: booking.id),
          ],
        ],
      ),
    );
  }
}

/// One-tap entry to [ReceiptSheet]. Lives below the inline
/// QuoteSummaryCard in CompletedBodyStub. Visible only when there's
/// a real quote to show — null-quote completions (e.g. inspection-
/// only) suppress the button entirely.
class _ViewReceiptButton extends StatelessWidget {
  const _ViewReceiptButton({required this.quote});
  final BookingQuote quote;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => ReceiptSheet.show(context, quote),
      icon: const Icon(
        Icons.open_in_full_rounded,
        size: 18,
        color: OrchestratorPalette.brandPrimary,
      ),
      label: const Text(
        'View receipt',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: OrchestratorPalette.brandPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: OrchestratorPalette.brandPrimary,
          width: 1.4,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(0, 44),
      ),
    );
  }
}

class CompletedInspectionOnlyBodyStub extends StatelessWidget {
  const CompletedInspectionOnlyBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    // Same customer-only review surface as `CompletedBodyStub`. An
    // inspection-only completion (customer declined the quote, paid
    // the Rs. 500 visit fee) is still a real tech-customer
    // interaction worth rating — backend lists this status in
    // `_ELIGIBLE_STATUSES` for the review service for the same
    // reason.
    final showReview =
        booking.viewerRole == BookingOrchestratorRole.customer;

    return _AnimatedBody(
      status: BookingStatus.completedInspectionOnly,
      message: booking.ui.bodyText,
      child: showReview
          ? BookingReviewBody(bookingId: booking.id)
          : null,
    );
  }
}

class CancelledBodyStub extends StatelessWidget {
  const CancelledBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.cancelled,
    message: booking.ui.bodyText,
  );
}

/// Shared body stub for both tech-acceptance failure terminal statuses
/// (`techDeclined` + `techNoResponse`). The differential copy lives in
/// the BE-driven `booking.ui.bodyText`; the status itself only picks
/// the muted hero icon variant via [AnimatedStatusIcon].
class RejectedBodyStub extends StatelessWidget {
  const RejectedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: booking.status,
    message: booking.ui.bodyText,
  );
}

class NoShowBodyStub extends StatelessWidget {
  const NoShowBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.noShow,
    message: booking.ui.bodyText,
  );
}

class DisputedBodyStub extends StatelessWidget {
  const DisputedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.disputed,
    message: booking.ui.bodyText,
  );
}

/// Audit P1-11: log a warning when the legacy PENDING status surfaces
/// here (predates migration 0007; should not occur in v1).
class UnknownBodyStub extends StatelessWidget {
  const UnknownBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    if (booking.status == BookingStatus.pending) {
      developer.log(
        'UnknownBodyStub rendering legacy PENDING booking ${booking.id}',
        name: 'orchestrator',
        level: 900,
      );
    }
    return _AnimatedBody(
      status: BookingStatus.unknown,
      message: booking.ui.bodyText,
    );
  }
}

// ─── Quote summary card (reusable) ────────────────────────────────────────

/// Renders a [BookingQuote] as a clean line-items + total card.
///
/// **Polish.** Brand-blue filled header strip with white receipt icon
/// and "Quote · revision N" label, then a white body listing items in
/// `_LineItemRow`, divider, and a bold "Total" / brand-blue amount row.
/// The header reads as the section title; the body breathes; the total
/// is unambiguous. Same surface family as the rest of the orchestrator
/// screen — brand-blue hairline border + soft brand shadow.
///
/// Public because the customer approval sheet (built separately) reuses it.
class QuoteSummaryCard extends StatelessWidget {
  const QuoteSummaryCard({super.key, required this.quote});
  final BookingQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.12),
        ),
        boxShadow: OrchestratorPalette.brandSoftShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filled brand header.
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OrchestratorPalette.brandPrimaryDeep,
                  OrchestratorPalette.brandPrimary,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quote',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.1,
                        ),
                      ),
                      // Revision label hidden on the first quote — for
                      // a first-time customer "Revision 1" reads as
                      // jargon. Surfaces only when the tech has
                      // re-submitted after a customer revision
                      // request, where "Revision 2" / "Revision 3"
                      // communicates that the quote was updated.
                      if (quote.revisionNumber > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Revision ${quote.revisionNumber}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Line items.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in quote.lineItems) ...[
                  _LineItemRow(
                    name: item.subServiceName,
                    qty: item.quantity,
                    lineTotal: item.lineTotal,
                  ),
                  if (item != quote.lineItems.last)
                    const SizedBox(height: 10),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    height: 1,
                    color: OrchestratorPalette.brandPrimary.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: OrchestratorPalette.inkSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Rs. ${_formatRupees(quote.totalAmount)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: OrchestratorPalette.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.name,
    required this.qty,
    required this.lineTotal,
  });

  final String name;
  final int qty;
  final int lineTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            qty == 1 ? name : '$name · ×$qty',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OrchestratorPalette.inkPrimary,
              height: 1.3,
            ),
          ),
        ),
        Text(
          'Rs. ${_formatRupees(lineTotal)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: OrchestratorPalette.inkPrimary,
          ),
        ),
      ],
    );
  }
}

/// Locale-naive comma grouping for rupees. Pakistan uses en-PK numbering
/// (lakhs/crores) but the entire app currently formats with Western
/// thousands separators — keeping consistent here. Public so the quote
/// builder + cash collection sheets share the same formatting.
String _formatRupees(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Shared rupee formatter — exposed so other orchestrator widgets
/// (quote builder, cash collection sheet) format the same way.
String formatRupees(int amount) => _formatRupees(amount);
