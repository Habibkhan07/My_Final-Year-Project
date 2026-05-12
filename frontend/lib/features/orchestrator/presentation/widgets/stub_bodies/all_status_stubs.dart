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
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/widgets/map/live_tracking_map.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
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
          Text(
            message.isEmpty ? _fallbackMessage(status) : message,
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

  /// Fallback message when the backend's bodyText is empty (some
  /// terminal states omit prose because the timeline pill already
  /// communicates the outcome).
  String _fallbackMessage(BookingStatus status) => switch (status) {
    BookingStatus.awaiting => 'Waiting for technician to accept…',
    BookingStatus.confirmed => 'Technician confirmed your booking.',
    BookingStatus.enRoute => 'Technician is on the way.',
    BookingStatus.arrived => 'Technician has arrived.',
    BookingStatus.inspecting => 'Technician is inspecting the issue.',
    BookingStatus.quoted => 'Quote ready for your review.',
    BookingStatus.inProgress => 'Work in progress.',
    BookingStatus.completed => 'Job complete — thank you!',
    BookingStatus.completedInspectionOnly => 'Inspection complete.',
    BookingStatus.cancelled => 'This booking was cancelled.',
    BookingStatus.rejected => 'This booking was rejected.',
    BookingStatus.noShow => 'Marked as no-show.',
    BookingStatus.disputed => 'A dispute has been opened on this booking.',
    BookingStatus.pending ||
    BookingStatus.unknown => 'Status not recognised.',
  };
}

// ─── Per-status stubs ─────────────────────────────────────────────────────

class AwaitingBodyStub extends StatelessWidget {
  const AwaitingBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.awaiting,
    message: booking.ui.bodyText,
  );
}

class ConfirmedBodyStub extends StatelessWidget {
  const ConfirmedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.confirmed,
    message: booking.ui.bodyText,
  );
}

/// Customer / tech viewing a booking that is EN_ROUTE.
///
/// Map fills the body — it IS the experience while the tech is on the
/// move. The booking's UI prose ("Tech will reach you in a few minutes")
/// sits below as supporting text.
class EnRouteBodyStub extends ConsumerWidget {
  const EnRouteBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final frame = ref.watch(technicianLocationStreamProvider(booking.id));
    final destination = LatLng(addr.latitude, addr.longitude);
    final isTech = booking.viewerRole == BookingOrchestratorRole.technician;
    final callTarget = resolveLiveCallTarget(booking);
    // Audit C6: surface non-running BroadcastState to the tech so they
    // know their location is NOT being shared. Customer view never sees
    // the banner — the controller stays `idle` for non-tech viewers.
    final broadcastState = isTech
        ? ref.watch(foregroundLocationServiceControllerProvider(booking.id))
        : BroadcastState.idle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BroadcastStateBanner(
            state: broadcastState,
            onOpenSettings: isTech
                ? () => ref
                      .read(
                        foregroundLocationServiceControllerProvider(
                          booking.id,
                        ).notifier,
                      )
                      .openSystemSettings()
                : null,
          ),
          // Map dominates the body. Bounded height (~55% of screen,
          // clamped) is required because BodySlot is hosted inside a
          // SingleChildScrollView in BookingOrchestratorScreen, which
          // hands its child unbounded vertical constraints — Expanded
          // would render at zero height (invisible map) or throw on
          // some platforms. The clamp keeps the map readable on small
          // phones and from dominating very tall screens.
          SizedBox(
            height: (MediaQuery.of(context).size.height * 0.55).clamp(
              320.0,
              520.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LiveTrackingMap(
                technicianPosition: frame == null
                    ? null
                    : LatLng(frame.latitude, frame.longitude),
                technicianHeadingDegrees: frame?.heading,
                lastFrameAt: frame?.frameArrivedAt,
                destination: destination,
                phase: TrackingPhase.enRoute,
                callPhoneNumber: callTarget.phone,
                callTooltip: callTarget.tooltip,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            booking.ui.bodyText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: OrchestratorPalette.inkSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
          ),
        ],
      ),
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

/// Customer-side ARRIVED layout — map-led (Foodpanda position).
///
/// **Layout (top → bottom inside the screen's scrollable body):**
///   1. Live tracking map — LARGE (~55% of screen, clamped 320–520px).
///      The map IS the focal element; the customer's job in this moment
///      is "find the tech outside", and the map answers that. No text
///      above the map competes for their first-glance attention.
///   2. Address recap — same surface language as the summary card, sits
///      directly under the map as the supporting context for the pin.
///   3. [BookingSummaryCard] — scroll-revealed. The call affordance
///      ("can't see the tech outside") is one scroll away. It does NOT
///      render here when the screen's always-on slot has it pinned for
///      other statuses; on ARRIVED that always-on slot is hidden so
///      this is the only mount point for the summary.
///
/// The "Your technician has arrived" message + "I'm coming out"
/// countdown button BOTH live in the pinned [ArrivalActionCard] at the
/// bottom of the screen (inside the action bar) — see
/// `arrival_action_card.dart` for the rationale.
class _CustomerArrivedBody extends ConsumerWidget {
  const _CustomerArrivedBody({required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final frame = ref.watch(technicianLocationStreamProvider(booking.id));
    final destination = LatLng(addr.latitude, addr.longitude);
    final callTarget = resolveLiveCallTarget(booking);
    final mapHeight = (MediaQuery.of(context).size.height * 0.55).clamp(
      320.0,
      520.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SizedBox(
            height: mapHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LiveTrackingMap(
                technicianPosition: frame == null
                    ? null
                    : LatLng(frame.latitude, frame.longitude),
                technicianHeadingDegrees: frame?.heading,
                lastFrameAt: frame?.frameArrivedAt,
                destination: destination,
                phase: TrackingPhase.arrived,
                callPhoneNumber: callTarget.phone,
                callTooltip: callTarget.tooltip,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _AddressRecapCard(addressText: addr.addressText),
        ),
        // Scroll-revealed summary card. Lives at the bottom of the
        // body so the customer can peek at "who's my tech / call them"
        // by scrolling, but doesn't see it during the map+arrive
        // moment unless they go looking.
        BookingSummaryCard(booking: booking),
        // Bottom inset so the last card doesn't bump against the
        // pinned arrival card below.
        const SizedBox(height: 8),
      ],
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
      Text(
        booking.ui.bodyText.isEmpty
            ? "You are at the customer's address."
            : booking.ui.bodyText,
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
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.inspecting,
    message: booking.ui.bodyText,
  );
}

/// QUOTED state.
///
/// **Customer view — post-arrival, face-to-face.** In this market the
/// customer and technician are physically together from the moment the
/// tech arrives. On QUOTED the customer is reading the line items with
/// the tech standing right there — this is NOT a remote ticket review.
/// The actions are:
///   * **Approve** — verbal "OK, let's do it", tap.
///   * **Negotiate price** — only present when there's labor on the
///     bill (`booking.subService.isFixedPrice == false`, or
///     `subService == null` for inspection-origin bookings). The tap
///     is the signal that flips the quote back so the tech can edit
///     it on their device while the customer watches. The verbal
///     bargain happens around the tap, not through it.
///     [SecondaryActionsSlot] owns the visibility + label rewrite.
///
/// Because both actions are taken with the tech literally next to the
/// customer, the [BookingTechnician]-identity card has no work to do
/// in this moment. Previously the always-on [BookingSummaryCard] sat
/// between the quote and the action bar, wedging tech-info between
/// what the customer is reading and what they're tapping. On
/// customer-QUOTED the screen suppresses that always-on slot and this
/// stub re-mounts the summary at the scroll-bottom — the call
/// affordance stays one scroll away for the rare follow-up after the
/// tech has left.
///
/// **Tech view.** Tech is the quote author here, watching for the
/// customer's decision. Tech card stays in its always-on slot above
/// the action bar (rendered by the screen, not this stub).
class QuotedBodyStub extends StatelessWidget {
  const QuotedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final quote = booking.activeQuote;
    final shell = _AnimatedBody(
      status: BookingStatus.quoted,
      message: booking.ui.bodyText,
      child: quote == null ? null : QuoteSummaryCard(quote: quote),
    );

    final isCustomerView =
        booking.viewerRole == BookingOrchestratorRole.customer;
    if (!isCustomerView) return shell;

    // BookingSummaryCard is itself a ConsumerWidget and reads any
    // providers it needs (ref.read on tap). This stub does not need
    // to be a ConsumerWidget — promoting it would just allocate an
    // extra ConsumerElement per QUOTED frame for no benefit.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        shell,
        BookingSummaryCard(booking: booking),
        const SizedBox(height: 8),
      ],
    );
  }
}

class InProgressBodyStub extends StatelessWidget {
  const InProgressBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.inProgress,
    message: booking.ui.bodyText,
  );
}

class CompletedBodyStub extends StatelessWidget {
  const CompletedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final quote = booking.activeQuote;
    return _AnimatedBody(
      status: BookingStatus.completed,
      message: booking.ui.bodyText,
      child: quote == null ? null : QuoteSummaryCard(quote: quote),
    );
  }
}

class CompletedInspectionOnlyBodyStub extends StatelessWidget {
  const CompletedInspectionOnlyBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.completedInspectionOnly,
    message: booking.ui.bodyText,
  );
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

class RejectedBodyStub extends StatelessWidget {
  const RejectedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _AnimatedBody(
    status: BookingStatus.rejected,
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
