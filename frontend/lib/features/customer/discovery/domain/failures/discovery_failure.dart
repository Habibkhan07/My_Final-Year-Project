/// Sealed class representing all possible failures when loading the Technician Discovery results.
sealed class DiscoveryFailure implements Exception {
  final String message;
  const DiscoveryFailure(this.message);
}

/// Thrown when the device has no active internet connection.
class DiscoveryNetworkFailure extends DiscoveryFailure {
  const DiscoveryNetworkFailure([String message = "No internet connection. Please check your settings."]) : super(message);
}

/// Thrown when the server returns a 400 Validation error.
class DiscoveryValidationFailure extends DiscoveryFailure {
  final Map<String, List<String>>? errors;
  const DiscoveryValidationFailure({
    required String message,
    this.errors,
  }) : super(message);
}

/// Thrown when the server returns a 401/403.
class DiscoveryUnauthorizedFailure extends DiscoveryFailure {
  const DiscoveryUnauthorizedFailure([String message = "You are not authorized to view this resource."]) : super(message);
}

/// Thrown when the server returns a 404.
class DiscoveryNotFoundFailure extends DiscoveryFailure {
  const DiscoveryNotFoundFailure(String message) : super(message);
}

/// Thrown when the backend returns a 500 error or is unreachable.
class DiscoveryServerFailure extends DiscoveryFailure {
  const DiscoveryServerFailure([String message = "An unexpected server error occurred."]) : super(message);
}

/// Catch-all for unexpected data parsing or logic errors.
class DiscoveryUnexpectedFailure extends DiscoveryFailure {
  const DiscoveryUnexpectedFailure(String message) : super(message);
}
