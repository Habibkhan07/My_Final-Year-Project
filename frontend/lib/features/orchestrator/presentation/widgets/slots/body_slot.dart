import 'package:flutter/material.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../domain/entities/booking_detail.dart';
import '../stub_bodies/all_status_stubs.dart';

/// The single switch on [BookingStatus] in the orchestrator feature.
/// Dart 3 patterns enforce exhaustiveness — adding a new status to the
/// enum will fail compilation here, signaling a missing stub. Lean on
/// the compiler.
///
/// Sessions 4–6 swap the stub bodies for the rich specialized widgets
/// (live map, quote builder, cash-collection sheet, edge-case modals).
/// The switch itself doesn't change.
class BodySlot extends StatelessWidget {
  const BodySlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    return switch (booking.status) {
      BookingStatus.awaiting => AwaitingBodyStub(booking: booking),
      BookingStatus.confirmed => ConfirmedBodyStub(booking: booking),
      BookingStatus.enRoute => EnRouteBodyStub(booking: booking),
      BookingStatus.arrived => ArrivedBodyStub(booking: booking),
      BookingStatus.inspecting => InspectingBodyStub(booking: booking),
      BookingStatus.quoted => QuotedBodyStub(booking: booking),
      BookingStatus.inProgress => InProgressBodyStub(booking: booking),
      BookingStatus.completed => CompletedBodyStub(booking: booking),
      BookingStatus.completedInspectionOnly => CompletedInspectionOnlyBodyStub(
        booking: booking,
      ),
      BookingStatus.cancelled => CancelledBodyStub(booking: booking),
      // Both tech-failure terminal statuses share the same body stub —
      // the BE drives all differential copy via the `ui` block.
      BookingStatus.techDeclined ||
      BookingStatus.techNoResponse => RejectedBodyStub(booking: booking),
      BookingStatus.noShow => NoShowBodyStub(booking: booking),
      BookingStatus.disputed => DisputedBodyStub(booking: booking),
      BookingStatus.pending ||
      BookingStatus.unknown => UnknownBodyStub(booking: booking),
    };
  }
}
