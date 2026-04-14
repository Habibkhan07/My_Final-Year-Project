import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/booking_entities.dart';
import 'availability_state.dart';
import 'dependency_injection.dart';

part 'availability_notifier.g.dart';

/// Manages available time slots for a technician on a specific date.
///
/// **Family design**: parameterised by [technicianId] + [date] so that changing
/// the selected date in the UI simply watches a new provider instance — no
/// explicit refresh method needed. Stale instances are auto-disposed.
///
/// **Intent**: [selectSlot] only mutates the in-memory [selectedSlot] — it does
/// not re-fetch. The selected slot's [isoStart]/[isoEnd] are passed verbatim
/// to [InstantBookingNotifier.book] — no timezone conversion.
@riverpod
class AvailabilityNotifier extends _$AvailabilityNotifier {
  @override
  Future<AvailabilityState> build({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  }) async {
    final slots = await ref.read(getAvailabilityUseCaseProvider).call(
          technicianId: technicianId,
          date: date,
          serviceId: serviceId,
          subServiceId: subServiceId,
        );

    return AvailabilityState(slots: slots, selectedSlot: null);
  }

  /// Marks [slot] as selected without re-fetching from the backend.
  ///
  /// Calling this on a slot that is already [selectedSlot] is a no-op.
  void selectSlot(AvailabilitySlotEntity slot) {
    final current = state.requireValue;
    if (current.selectedSlot == slot) return;
    state = AsyncData(current.copyWith(selectedSlot: slot));
  }
}
