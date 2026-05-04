// Contract: fed by `GET /api/bookings/` (paginated list endpoint).
// Wire spec: `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` §1.4.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'booking_status.dart';
import 'booking_ui_tone.dart';

part 'customer_booking.freezed.dart';

/// A single booking summary as it appears in the customer's "My Bookings"
/// list. Card-shaped — intentionally lighter than the (forthcoming)
/// detail entity. No full address, no sub-service description, no
/// timeline.
///
/// Field notes:
///
///   * [status] — typed enum. The realtime event-patch mapper compares
///     against this when applying `job_accepted` / `booking_rejected`
///     transitions. Widgets never switch on it for display copy.
///
///   * [ui] — server-resolved dumb-UI block. The card widget switches
///     on `ui.badgeTone` to pick a design token but never on `status`
///     for headline/badge text. When the realtime patch mapper runs,
///     it recomputes this entire block from the same status → ui table
///     the server uses (see CUSTOMER_BOOKINGS_API.md §1.7).
///
///   * [scheduledStart] / [scheduledEnd] / [createdAt] — UTC. Widgets
///     call `.toLocal()` for display.
///
///   * [addressLabel] — pre-composed `"Home — DHA Phase 5, Lahore"`
///     one-liner. Null when the booking's address FK is `SET_NULL`
///     (deleted address row) — widgets hide the row in that case.
///
///   * [price.amount] — int rupees, for sort/math/analytics.
///   * [price.uiLabel] — pre-formatted `"Rs. 2,500"`. Widgets render
///     verbatim; locale-aware comma grouping is done once on the server.
@freezed
abstract class CustomerBooking with _$CustomerBooking {
  const factory CustomerBooking({
    required int id,
    required BookingStatus status,
    required BookingService service,
    required BookingTechnician technician,
    required String? addressLabel,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required DateTime createdAt,
    required BookingPrice price,
    required BookingUi ui,
  }) = _CustomerBooking;
}

/// Service-name + Flutter `IconAssets` key. See CLAUDE.md catalog image
/// design for the icon resolution contract — `iconName` is the SVG
/// filename without `.svg` (e.g. `"ac_repair"`).
@freezed
abstract class BookingService with _$BookingService {
  const factory BookingService({
    required String name,
    required String iconName,
  }) = _BookingService;
}

@freezed
abstract class BookingTechnician with _$BookingTechnician {
  const factory BookingTechnician({
    required int id,
    required String displayName,
    required String? profilePictureUrl,
  }) = _BookingTechnician;
}

@freezed
abstract class BookingPrice with _$BookingPrice {
  const factory BookingPrice({
    required int amount,
    required String context,
    required String uiLabel,
  }) = _BookingPrice;
}

/// Server-resolved display block. The card switches on [badgeTone] for
/// design tokens; [badgeText] and [headline] render verbatim.
@freezed
abstract class BookingUi with _$BookingUi {
  const factory BookingUi({
    required String badgeText,
    required BookingUiTone badgeTone,
    required String headline,
  }) = _BookingUi;
}
