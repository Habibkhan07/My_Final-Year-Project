// Per-status body widgets. Each is intentionally minimal — sessions
// 4–6 replace the specialized parts (live map, quote builder, cash
// collection sheet, cancel/reschedule modals) but keep the surrounding
// chrome these stubs establish. Every stub reads its prose from
// `booking.ui.bodyText` (dumb-UI principle); none branches on status
// for copy or computes its own.
//
// Session 4: EnRouteBodyStub and ArrivedBodyStub render LiveTrackingMap
// against the booking's destination + the latest tech_gps frame from
// `technicianLocationStreamProvider`. The other 13 stubs are unchanged.
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

class AwaitingBodyStub extends StatelessWidget {
  const AwaitingBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.schedule, booking: booking);
}

class ConfirmedBodyStub extends StatelessWidget {
  const ConfirmedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.check_circle_outline, booking: booking);
}

/// Customer / tech viewing a booking that is EN_ROUTE.
///
/// Map fills the body — it IS the experience while the tech is on the
/// move. The booking's UI prose ("Tech will reach you in a few minutes")
/// sits below as supporting text.
///
/// Audit H11 (W-8): the tech viewer dials the customer; the customer
/// viewer dials configured support (`AppConstants.supportPhoneNumber`).
/// The customer-side FAB stays hidden ONLY when support is unconfigured
/// (dev builds), not unconditionally. Proper fix is to expose
/// `technician.phoneNo` in the wire contract — flag
/// #booking-detail-tech-phone tracks that.
class EnRouteBodyStub extends ConsumerWidget {
  const EnRouteBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addr = booking.address;
    if (addr == null) {
      // Defensive — backend always serializes address for non-terminal
      // bookings, but the contract allows null. Fall back to plain
      // body text rather than rendering a map with a default centre.
      return _IconWithBody(icon: Icons.directions_bike, booking: booking);
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
            // Audit C2: deep-link to OS settings on the two
            // permission-denied variants. Tech-side only — customer
            // viewers never see the banner because the controller
            // stays `idle` for them.
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
          // Map fills the body. SizedBox + Expanded gives the map all
          // remaining vertical space minus the body text caption.
          Expanded(
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Customer / tech viewing a booking that is ARRIVED.
///
/// Smaller map (220px tall) — the tech is at the door, so the visual
/// emphasis shifts to "what's next" prose. Marker icon swaps from
/// motorbike to walking-person via [TrackingPhase.arrived]; staleness
/// detection stays on (tech going inside = GPS drops; legitimate
/// signal that the customer might want to know about).
class ArrivedBodyStub extends ConsumerWidget {
  const ArrivedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addr = booking.address;
    if (addr == null) {
      return _IconWithBody(icon: Icons.location_on, booking: booking);
    }
    final frame = ref.watch(technicianLocationStreamProvider(booking.id));
    final destination = LatLng(addr.latitude, addr.longitude);
    final isTech = booking.viewerRole == BookingOrchestratorRole.technician;
    final callTarget = resolveLiveCallTarget(booking);
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
            // Audit C2: deep-link to OS settings on the two
            // permission-denied variants. Tech-side only — customer
            // viewers never see the banner because the controller
            // stays `idle` for them.
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
          SizedBox(
            // Audit W-20 (Batch D): scale ARRIVED map height by screen
            // size so the layout stays balanced on small phones (the
            // hardcoded 220 left only ~480 px for body content on
            // sub-700-px screens). Clamp to [180, 260] so very tall
            // phones don't get a comically large map and very short
            // ones still get a readable map.
            height: (MediaQuery.of(context).size.height * 0.28).clamp(
              180.0,
              260.0,
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
                phase: TrackingPhase.arrived,
                callPhoneNumber: callTarget.phone,
                callTooltip: callTarget.tooltip,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                booking.ui.bodyText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
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
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.search, booking: booking);
}

class QuotedBodyStub extends StatelessWidget {
  const QuotedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final quote = booking.activeQuote;
    if (quote == null) {
      return _IconWithBody(icon: Icons.receipt_long_outlined, booking: booking);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuoteCard(quote: quote),
          const SizedBox(height: 12),
          Text(booking.ui.bodyText),
        ],
      ),
    );
  }
}

class InProgressBodyStub extends StatelessWidget {
  const InProgressBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.build_outlined, booking: booking);
}

class CompletedBodyStub extends StatelessWidget {
  const CompletedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.check_circle, booking: booking);
}

class CompletedInspectionOnlyBodyStub extends StatelessWidget {
  const CompletedInspectionOnlyBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.receipt_outlined, booking: booking);
}

class CancelledBodyStub extends StatelessWidget {
  const CancelledBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.event_busy, booking: booking);
}

class RejectedBodyStub extends StatelessWidget {
  const RejectedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.do_not_disturb, booking: booking);
}

class NoShowBodyStub extends StatelessWidget {
  const NoShowBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.person_off_outlined, booking: booking);
}

class DisputedBodyStub extends StatelessWidget {
  const DisputedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.gavel_outlined, booking: booking);
}

/// Audit P1-11: log a warning when the legacy PENDING status surfaces
/// here (predates migration 0007; should not occur in v1). Helps spot
/// rollout-window regressions without surfacing a confusing UI.
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
    final text = booking.ui.bodyText.isEmpty
        ? 'Status not recognized.'
        : booking.ui.bodyText;
    return _IconWithBody(
      icon: Icons.help_outline,
      booking: booking,
      overrideText: text,
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────

class _IconWithBody extends StatelessWidget {
  const _IconWithBody({
    required this.icon,
    required this.booking,
    this.overrideText,
  });

  final IconData icon;
  final BookingDetail booking;
  final String? overrideText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            overrideText ?? booking.ui.bodyText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// _MapPlaceholder removed in session 4 — EnRouteBodyStub and
// ArrivedBodyStub now render `LiveTrackingMap` directly.

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final BookingQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Quote · revision ${quote.revisionNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in quote.lineItems) ...[
              _LineItemRow(
                name: item.subServiceName,
                qty: item.quantity,
                lineTotal: item.lineTotal,
              ),
              const SizedBox(height: 6),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleSmall),
                Text(
                  'Rs. ${_format(quote.totalAmount)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            qty == 1 ? name : '$name · ×$qty',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          'Rs. ${_format(lineTotal)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Locale-naive comma grouping for rupees. Pakistan uses the en-PK
/// numbering system (lakhs/crores) but the entire app currently formats
/// with Western thousands separators — keeping consistent here.
String _format(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
