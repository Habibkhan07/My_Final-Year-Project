// Contract: fed by `GET /api/technicians/me/scheduled-jobs/`.
// Wire spec: `backend/technicians/api/SCHEDULED_JOBS_API.md` §1.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../customer/bookings/domain/entities/booking_ui_tone.dart';

part 'scheduled_job.freezed.dart';

/// A single row in the technician's "Schedule" tab — audience-flipped
/// mirror of [CustomerBooking].
///
/// Same underlying `JobBooking` row as the customer side; the wire
/// shape differs by what side the user is on:
///
///   * Customer wire surfaces `technician` + `price`.
///   * Tech wire surfaces `customer` + `payout`.
///
/// The [BookingStatus] enum and [BookingUiTone] enum are intentionally
/// shared imports from the customer feature — both surfaces consume the
/// same `JobBooking.STATUS_*` wire values from the backend, and
/// duplicating the parse table would invite drift. Future cleanup
/// (tracked in `flag.md`) will extract them to `core/booking/` once a
/// third consumer appears.
///
/// Field notes:
///
///   * [status] — typed enum. Realtime listeners compare against this
///     when applying transition events. Widgets never switch on it for
///     display copy.
///
///   * [ui] — server-resolved dumb-UI block. The card widget switches
///     on `ui.badgeTone` to pick a design token but never on `status`
///     for headline/badge text. See `SCHEDULED_JOBS_API.md` §1.8 for
///     the canonical status→ui table.
///
///   * [scheduledStart] / [scheduledEnd] / [createdAt] — UTC. Widgets
///     call `.toLocal()` for display.
///
///   * [addressLabel] — pre-composed `"Home — DHA Phase 5, Lahore"`.
///     Null when the booking's address FK is `SET_NULL` (deleted
///     address row) — widgets hide the row in that case.
///
///   * [payout.amount] — int rupees, for sort/math/analytics. Source:
///     `JobCommission.tech_net_amount` when the row exists (COMPLETED
///     with commission); otherwise projected `price_amount * 0.80`.
///   * [payout.context] — short label feeding the card's secondary line
///     ("After Rs. X commission", "Payout", "Forgone", "Inspection fee
///     (cash)", "Est. payout"). Display-only.
///   * [payout.uiLabel] — pre-formatted `"Rs. 2,500"`. Widgets render
///     verbatim.
@freezed
abstract class ScheduledJob with _$ScheduledJob {
  const factory ScheduledJob({
    required int id,
    required BookingStatus status,
    required ScheduledJobService service,
    required ScheduledJobCustomer customer,
    required String? addressLabel,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required DateTime createdAt,
    required PayoutBlock payout,
    required ScheduledJobUi ui,
  }) = _ScheduledJob;
}

/// Service-name + Flutter `IconAssets` key. See CLAUDE.md catalog image
/// design — `iconName` is the SVG filename without `.svg` (e.g.
/// `"ac_repair"`).
@freezed
abstract class ScheduledJobService with _$ScheduledJobService {
  const factory ScheduledJobService({
    required String name,
    required String iconName,
  }) = _ScheduledJobService;
}

/// The customer counterparty of this job. `profilePictureUrl` is always
/// null in v1 — `CustomerProfile` has no avatar field yet. The card
/// renders initials when null.
@freezed
abstract class ScheduledJobCustomer with _$ScheduledJobCustomer {
  const factory ScheduledJobCustomer({
    required int id,
    required String displayName,
    required String? profilePictureUrl,
  }) = _ScheduledJobCustomer;
}

/// What the tech keeps from this job, after platform commission.
///
/// The [context] field distinguishes "ledger-truth" payouts (commission
/// row exists on the booking) from projected ones. See
/// `_resolve_payout_block` in the backend selector for the seven
/// branches that produce this struct.
@freezed
abstract class PayoutBlock with _$PayoutBlock {
  const factory PayoutBlock({
    required int amount,
    required String context,
    required String uiLabel,
  }) = _PayoutBlock;
}

/// Server-resolved display block. The card switches on [badgeTone] for
/// design tokens; [badgeText] and [headline] render verbatim.
@freezed
abstract class ScheduledJobUi with _$ScheduledJobUi {
  const factory ScheduledJobUi({
    required String badgeText,
    required BookingUiTone badgeTone,
    required String headline,
  }) = _ScheduledJobUi;
}
