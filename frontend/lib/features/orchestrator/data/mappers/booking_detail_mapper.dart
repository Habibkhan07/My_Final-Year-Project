import '../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../customer/bookings/domain/entities/booking_ui_tone.dart';
import '../../domain/entities/booking_cash_collection.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_item.dart';
import '../../domain/entities/booking_orchestrator_role.dart';
import '../../domain/entities/booking_phase_timestamps.dart';
import '../../domain/entities/booking_pricing.dart';
import '../../domain/entities/booking_quote.dart';
import '../../domain/entities/booking_ui_block.dart';
import '../models/booking_detail_model.dart';
import '../models/booking_item_model.dart';
import '../models/booking_quote_model.dart';
import '../models/booking_ui_block_model.dart';

/// DTO → domain conversion for the orchestrator detail response.
///
/// Two non-trivial coercions happen here:
///
///   1. **Decimal-string → int rupees.** Backend serializes
///      `DecimalField` as strings (`"500.00"`). Pakistan market has no
///      paisa, so `int.parse` would throw on the `.00` suffix. We use
///      `num.parse(s).toInt()` which truncates the fractional part
///      losslessly for whole-rupee values.
///
///   2. **Viewer role derivation.** Server returns 403
///      `not_a_participant` for any non-participant before the response
///      reaches us, so "not the customer" must be the technician. We
///      derive purely from `customer.id == currentUserId`. (The
///      technician sub-object's `id` is `TechnicianProfile.id`, not
///      `User.id`, so it can't be compared against the auth user id
///      directly anyway.)
class BookingDetailMapper {
  const BookingDetailMapper._();

  static BookingDetail toDomain(
    BookingDetailModel model, {
    required int currentUserId,
  }) {
    final viewerRole = model.customer.id == currentUserId
        ? BookingOrchestratorRole.customer
        : BookingOrchestratorRole.technician;

    return BookingDetail(
      id: model.id,
      status: BookingStatus.fromWire(model.status),
      service: BookingService(
        id: model.service.id,
        name: model.service.name,
        iconName: model.service.iconName,
      ),
      subService: model.subService == null
          ? null
          : BookingSubService(
              id: model.subService!.id,
              name: model.subService!.name,
              isFixedPrice: model.subService!.isFixedPrice,
              basePrice: _parseRupees(model.subService!.basePrice)!,
              maxPrice: _parseRupees(model.subService!.maxPrice),
            ),
      technician: BookingTechnician(
        id: model.technician.id,
        displayName: model.technician.displayName,
        profilePictureUrl: model.technician.profilePictureUrl,
      ),
      customer: BookingCustomer(
        id: model.customer.id,
        fullName: model.customer.fullName,
        phoneNo: model.customer.phoneNo,
      ),
      address: model.address == null
          ? null
          : BookingAddress(
              label: model.address!.label,
              latitude: double.parse(model.address!.latitude),
              longitude: double.parse(model.address!.longitude),
              addressText: model.address!.addressText,
            ),
      addressSnapshot: model.addressSnapshot,
      scheduledStart: DateTime.parse(model.scheduledStart),
      scheduledEnd: DateTime.parse(model.scheduledEnd),
      phaseTimestamps: _phaseTimestamps(model.phaseTimestamps),
      pricing: _pricing(model.pricing),
      cashCollection: _cashCollection(model.cashCollection),
      parentBookingId: model.parentBookingId,
      childBookingId: model.childBookingId,
      cancelReason: model.cancelReason,
      noShowActor: model.noShowActor,
      activeQuote:
          model.activeQuote == null ? null : _quote(model.activeQuote!),
      bookingItems: model.bookingItems.map(_bookingItem).toList(),
      openTicketsCount: model.openTicketsCount,
      ui: _uiBlock(model.ui),
      availableTransitions: model.availableTransitions,
      viewerRole: viewerRole,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  /// Parse a Decimal-string (`"500.00"`) to integer rupees. Returns null
  /// when [raw] is null. Throws on malformed input — the error surfaces
  /// at the boundary rather than silently producing wrong totals.
  static int? _parseRupees(String? raw) {
    if (raw == null) return null;
    return num.parse(raw).toInt();
  }

  static DateTime? _parseDateTime(String? raw) =>
      raw == null ? null : DateTime.parse(raw);

  static BookingPhaseTimestamps _phaseTimestamps(
    BookingDetailPhaseTimestampsModel m,
  ) =>
      BookingPhaseTimestamps(
        acceptedAt: _parseDateTime(m.acceptedAt),
        enRouteStartedAt: _parseDateTime(m.enRouteStartedAt),
        arrivedAt: _parseDateTime(m.arrivedAt),
        inspectionStartedAt: _parseDateTime(m.inspectionStartedAt),
        quoteFirstSubmittedAt: _parseDateTime(m.quoteFirstSubmittedAt),
        workStartedAt: _parseDateTime(m.workStartedAt),
        completedAt: _parseDateTime(m.completedAt),
      );

  static BookingPricing _pricing(BookingDetailPricingModel m) => BookingPricing(
        inspectionFee: _parseRupees(m.inspectionFee),
        baseServicesTotal: _parseRupees(m.baseServicesTotal),
        discountApplied: _parseRupees(m.discountApplied),
        finalCashToCollect: _parseRupees(m.finalCashToCollect),
        promoCodeSnapshot: m.promoCodeSnapshot,
        promoDiscountSnapshot: _parseRupees(m.promoDiscountSnapshot),
      );

  static BookingCashCollection _cashCollection(
    BookingDetailCashCollectionModel m,
  ) =>
      BookingCashCollection(
        amount: _parseRupees(m.amount),
        at: _parseDateTime(m.at),
        method: m.method,
      );

  static BookingQuote _quote(BookingQuoteModel m) => BookingQuote(
        id: m.id,
        bookingId: m.bookingId,
        revisionNumber: m.revisionNumber,
        status: BookingQuoteStatus.fromWire(m.status),
        totalAmount: _parseRupees(m.totalAmount)!,
        isUpsell: m.isUpsell,
        lineItems: m.lineItems.map(_lineItem).toList(),
        submittedAt: _parseDateTime(m.submittedAt),
      );

  static BookingQuoteLineItem _lineItem(BookingQuoteLineItemModel m) =>
      BookingQuoteLineItem(
        id: m.id,
        subServiceId: m.subServiceId,
        subServiceName: m.subServiceName,
        quantity: m.quantity,
        pricedAt: _parseRupees(m.pricedAt)!,
        lineTotal: _parseRupees(m.lineTotal)!,
      );

  static BookingItem _bookingItem(BookingItemModel m) => BookingItem(
        id: m.id,
        subServiceId: m.subServiceId,
        subServiceName: m.subServiceName,
        quantity: m.quantity,
        priceCharged: _parseRupees(m.priceCharged)!,
        lineTotal: _parseRupees(m.lineTotal)!,
        sourcedQuoteId: m.sourcedQuoteId,
      );

  static BookingUiBlock _uiBlock(BookingUiBlockModel m) => BookingUiBlock(
        statusLabel: m.statusLabel,
        bodyText: m.bodyText,
        primaryAction:
            m.primaryAction == null ? null : _action(m.primaryAction!),
        secondaryActions: m.secondaryActions.map(_action).toList(),
        showTracking: m.showTracking,
        showQuoteCard: m.showQuoteCard,
        showDisputeButton: m.showDisputeButton,
        tone: BookingUiTone.fromWire(m.tone),
      );

  static BookingUiAction _action(BookingUiActionModel m) => BookingUiAction(
        label: m.label,
        endpoint: m.endpoint,
        method: m.method,
        style: BookingUiActionStyle.fromWire(m.style),
      );
}
