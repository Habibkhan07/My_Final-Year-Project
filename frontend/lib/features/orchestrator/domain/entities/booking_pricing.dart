import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_pricing.freezed.dart';

/// Snapshot of money fields on the booking. All are integer rupees in
/// the domain — the data mapper coerces backend Decimal-strings (`"500.00"`)
/// to `int` once at the boundary so widgets can format without re-parsing.
///
/// Pakistan market has no paisa, so integer rupees lose no precision.
///
/// Field semantics (mirrors `JobBooking` columns):
///   * [inspectionFee] — Rs. 500 base; carried to the child booking on
///     reschedule, deducted from `finalCashToCollect` on quote-approve.
///   * [baseServicesTotal] — sum of accepted [BookingItem.lineTotal]s.
///   * [discountApplied] — promo or platform discount.
///   * [finalCashToCollect] — what the technician's "Cash collected"
///     button charges. Set on quote decision (approve = base − fee;
///     decline = fee only).
///   * [promoCodeSnapshot] / [promoDiscountSnapshot] — frozen at booking
///     creation; survives promo-code changes mid-job.
@freezed
abstract class BookingPricing with _$BookingPricing {
  const factory BookingPricing({
    int? inspectionFee,
    int? baseServicesTotal,
    int? discountApplied,
    int? finalCashToCollect,
    String? promoCodeSnapshot,
    int? promoDiscountSnapshot,
  }) = _BookingPricing;
}
