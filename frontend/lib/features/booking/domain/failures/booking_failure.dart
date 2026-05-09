/// Sealed class representing all possible failures in the Booking feature.
///
/// Both customers (creating bookings) and technicians (managing bookings) use
/// this shared failure hierarchy since [JobBooking] is a neutral domain object.
sealed class BookingFailure implements Exception {
  final String message;
  const BookingFailure(this.message);
}

/// Device has no active internet connection.
class BookingNetworkFailure extends BookingFailure {
  const BookingNetworkFailure([
    String message = 'No internet connection. Please check your settings.',
  ]) : super(message);
}

/// Backend returned 404 — technician does not exist or is not APPROVED.
class BookingTechnicianNotFoundFailure extends BookingFailure {
  const BookingTechnicianNotFoundFailure([
    String message = 'Technician not available.',
  ]) : super(message);
}

/// address_id does not belong to the authenticated user (IDOR-safe: same
/// failure whether the address is missing or belongs to another account).
class BookingInvalidAddressFailure extends BookingFailure {
  const BookingInvalidAddressFailure([
    String message = 'No matching address found for this account.',
  ]) : super(message);
}

/// Customer's address is outside the technician's service radius.
///
/// [message] is already human-readable from the backend
/// (e.g. "Your address is 14.2 km away (limit: 10 km)") — display it directly.
class BookingOutOfServiceAreaFailure extends BookingFailure {
  const BookingOutOfServiceAreaFailure(String message) : super(message);
}

/// The selected slot was taken by another customer between the availability
/// check and this booking attempt (classic race condition).
///
/// UI should pop back to the availability screen and show a Snackbar.
class BookingSlotUnavailableFailure extends BookingFailure {
  const BookingSlotUnavailableFailure([
    String message = 'This time slot was just booked. Please choose another.',
  ]) : super(message);
}

/// Generic 400 validation error not covered by a more specific failure.
class BookingValidationFailure extends BookingFailure {
  final Map<String, List<String>>? errors;
  const BookingValidationFailure({required String message, this.errors})
    : super(message);
}

/// Backend returned a 5xx or is otherwise unreachable.
class BookingServerFailure extends BookingFailure {
  const BookingServerFailure([
    String message = 'An unexpected server error occurred.',
  ]) : super(message);
}

/// Catch-all for unexpected parsing or logic errors.
class BookingUnexpectedFailure extends BookingFailure {
  const BookingUnexpectedFailure(String message) : super(message);
}
