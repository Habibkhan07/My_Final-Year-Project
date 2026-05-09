// lib/features/customer/home/domain/failures/home_failure.dart

/// Sealed class representing all possible failures when loading the Customer Home Feed.
sealed class HomeFailure implements Exception {
  final String message;
  const HomeFailure(this.message);
}

/// Thrown when the device has no active internet connection.
class HomeNetworkFailure extends HomeFailure {
  const HomeNetworkFailure([
    super.message = "No internet connection. Please check your settings.",
  ]);
}

/// Thrown when the backend returns a 500 error or is unreachable.
class HomeServerFailure extends HomeFailure {
  const HomeServerFailure(super.message);
}

/// Thrown when the backend returns unexpected JSON structures that fail to parse.
class HomeParsingFailure extends HomeFailure {
  const HomeParsingFailure([super.message = "Failed to parse home feed data."]);
}
