import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/booking_entities.dart';
import 'dependency_injection.dart';

part 'booking_notifier.g.dart';

/// Manages the instant booking creation mutation.
///
/// **State**: starts as [AsyncData(null)] — no booking attempted yet.
/// Transitions: null → AsyncLoading → AsyncData(entity) or AsyncError.
///
/// **Tier 3 (crash recovery)**: on [AsyncData], the UI layer must immediately
/// write [CreatedBookingEntity.bookingId] to SharedPreferences so the Active
/// Job Screen can be restored after a crash. This is intentionally a UI
/// responsibility — the notifier only owns the network result.
///
/// **409 UX**: when state is [AsyncError] with [BookingSlotUnavailableFailure],
/// the UI must pop back to the availability screen so the customer can
/// pick a different slot.
@riverpod
class InstantBookingNotifier extends _$InstantBookingNotifier {
  @override
  AsyncValue<CreatedBookingEntity?> build() => const AsyncData(null);

  /// Submits the booking. All parameters are required by the backend contract
  /// except [subServiceId] / [promotionId], which are scenario-dependent.
  ///
  /// [scheduledStart] and [scheduledEnd] must be the [AvailabilitySlotEntity.isoStart]
  /// and [AvailabilitySlotEntity.isoEnd] values — pass them through verbatim.
  ///
  /// [serviceId] is the parent category the customer was browsing.
  /// [subServiceId] is set for fixed-price gigs (Scenario A) or labor matches
  /// (Scenario B); omitted for parent-category / inspection (Scenario C).
  /// [promotionId] is set only when the customer arrived via a promo banner
  /// (Scenario D). Pairing it with a fixed-price [subServiceId] is rejected
  /// by the server's promo firewall — this notifier asserts the same locally
  /// (defensive: server enforces, but failing client-side prevents a wasted
  /// round trip).
  Future<void> book({
    required int technicianId,
    required int addressId,
    required int serviceId,
    int? subServiceId,
    int? promotionId,
    required String scheduledStart,
    required String scheduledEnd,
    required String priceAmount,
  }) async {
    assert(
      !(subServiceId != null && promotionId != null),
      'Promotions cannot be applied to fixed-price sub-services. '
      'The server rejects this combination via the promo firewall.',
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(createInstantBookingUseCaseProvider).call(
            technicianId: technicianId,
            addressId: addressId,
            serviceId: serviceId,
            subServiceId: subServiceId,
            promotionId: promotionId,
            scheduledStart: scheduledStart,
            scheduledEnd: scheduledEnd,
            priceAmount: priceAmount,
          ),
    );
  }
}
