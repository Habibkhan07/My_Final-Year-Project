/// All failure states for the customer addresses feature.
sealed class AddressFailure implements Exception {
  final String message;
  const AddressFailure(this.message);

  @override
  String toString() => message;
}

/// Device has no active internet and the local cache is empty.
class AddressNetworkFailure extends AddressFailure {
  const AddressNetworkFailure([
    super.message = 'No internet connection. Please check your settings.',
  ]);
}

/// Backend returned a non-2xx response.
class AddressServerFailure extends AddressFailure {
  const AddressServerFailure(super.message);
}

/// Backend returned unexpected JSON that failed to parse.
class AddressParsingFailure extends AddressFailure {
  const AddressParsingFailure([
    super.message = 'Failed to parse address data.',
  ]);
}

/// DELETE returned 404 — address does not exist or belongs to another user.
class AddressNotFoundFailure extends AddressFailure {
  const AddressNotFoundFailure([super.message = 'Address not found.']);
}

/// User denied location permission.
class AddressLocationPermissionDenied extends AddressFailure {
  const AddressLocationPermissionDenied([
    super.message = 'Location permission denied. Please enable it in Settings.',
  ]);
}

/// Device GPS is turned off.
class AddressLocationServiceDisabled extends AddressFailure {
  const AddressLocationServiceDisabled([
    super.message = 'Location services are disabled. Please turn on GPS.',
  ]);
}
