// Contract: fed by `GET /api/bookings/<id>/`.
// Wire spec: `backend/bookings/api/BOOKINGS_API.md` §8.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../customer/bookings/domain/entities/booking_status.dart';
import 'booking_cash_collection.dart';
import 'booking_item.dart';
import 'booking_orchestrator_role.dart';
import 'booking_phase_timestamps.dart';
import 'booking_pricing.dart';
import 'booking_quote.dart';
import 'booking_ui_block.dart';

part 'booking_detail.freezed.dart';

/// Top-level entity hydrating the orchestrator screen.
///
/// Status-driven UI flows from [ui]; the only place the screen branches
/// on [status] is the body slot's exhaustive switch (Dart 3 patterns
/// enforce coverage at compile time).
///
/// [viewerRole] is derived in the data-layer mapper by comparing the
/// authenticated user's id against [customer.id]. Server returns 403
/// `not_a_participant` for any non-participant before the response
/// reaches us, so "not the customer" implies the technician.
///
/// [parentBookingId] is non-null for the child of a reschedule chain
/// (§12 of sprint meta). The screen surfaces a small "Rescheduled from
/// #N" hint when set.
///
/// [activeQuote] is non-null at QUOTED (the active SUBMITTED revision)
/// and at IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY (the most
/// recent decision-quote, surfaced on the receipt card).
@freezed
abstract class BookingDetail with _$BookingDetail {
  const factory BookingDetail({
    required int id,
    required BookingStatus status,
    required BookingService service,
    BookingSubService? subService,
    required BookingTechnician technician,
    required BookingCustomer customer,
    BookingAddress? address,
    required String addressSnapshot,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required BookingPhaseTimestamps phaseTimestamps,
    required BookingPricing pricing,
    required BookingCashCollection cashCollection,
    int? parentBookingId,
    int? childBookingId,
    String? cancelReason,
    String? noShowActor,
    BookingQuote? activeQuote,
    @Default([]) List<BookingItem> bookingItems,
    @Default(0) int openTicketsCount,
    required BookingUiBlock ui,
    @Default([]) List<String> availableTransitions,
    required BookingOrchestratorRole viewerRole,
  }) = _BookingDetail;
}

@freezed
abstract class BookingService with _$BookingService {
  const factory BookingService({
    required int id,
    required String name,
    required String iconName,
  }) = _BookingService;
}

@freezed
abstract class BookingSubService with _$BookingSubService {
  const factory BookingSubService({
    required int id,
    required String name,
    required bool isFixedPrice,
    required int basePrice,
    int? maxPrice,
  }) = _BookingSubService;
}

@freezed
abstract class BookingTechnician with _$BookingTechnician {
  const factory BookingTechnician({
    required int id,
    required String displayName,
    String? profilePictureUrl,
  }) = _BookingTechnician;
}

@freezed
abstract class BookingCustomer with _$BookingCustomer {
  const factory BookingCustomer({
    required int id,
    required String fullName,
    required String phoneNo,
  }) = _BookingCustomer;
}

@freezed
abstract class BookingAddress with _$BookingAddress {
  const factory BookingAddress({
    required String label,
    required double latitude,
    required double longitude,
    required String addressText,
  }) = _BookingAddress;
}
