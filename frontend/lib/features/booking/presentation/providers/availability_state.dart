import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/booking_entities.dart';

part 'availability_state.freezed.dart';

/// State for the availability slot picker screen.
///
/// [slots] is the full list returned by the backend for the selected date.
/// [selectedSlot] is null until the customer taps a slot — the UI uses this
/// to enable/disable the "Confirm" button and build the booking payload.
@freezed
abstract class AvailabilityState with _$AvailabilityState {
  const factory AvailabilityState({
    required List<AvailabilitySlotEntity> slots,
    AvailabilitySlotEntity? selectedSlot,
  }) = _AvailabilityState;
}
