// domain/failures/technician_failure.dart

sealed class TechnicianFailure implements Exception {
  const TechnicianFailure();
}

// 1. Corresponds to 400 (Backend code: "validation_error")
// Used for: Invalid CNIC format, missing fields
class InvalidOnboardingInput extends TechnicianFailure {
  final Map<String, dynamic> errors;
  const InvalidOnboardingInput(this.errors);
}

// 2. Corresponds to 404 (Backend code: "not_found")
// Used for: Expired Image UUIDs (The "Session Timeout" scenario)
class OnboardingSessionExpired extends TechnicianFailure {
  final String message;
  const OnboardingSessionExpired(this.message);
}

// 3. Corresponds to 409 (Backend code: "resource_conflict")
// Used for: Duplicate CNIC
class DuplicateTechnician extends TechnicianFailure {
  final String message;
  const DuplicateTechnician(this.message);
}

// 4. Corresponds to 500 or Network
class OnboardingServerFailure extends TechnicianFailure {
  final String message;
  const OnboardingServerFailure(this.message);
}

// NEW: Corresponds to 401 (Backend code: "unauthorized")
class OnboardingUnauthorized extends TechnicianFailure {
  final String message;
  const OnboardingUnauthorized(this.message);
}

class OnboardingNetworkFailure extends TechnicianFailure {
  final String message;
  const OnboardingNetworkFailure([this.message = "No internet connection"]);
}

// NEW SAFEGUARD 2: Bad Data (JSON Parsing failed)
class OnboardingParsingFailure extends TechnicianFailure {
  final String message;
  const OnboardingParsingFailure(this.message);
}
