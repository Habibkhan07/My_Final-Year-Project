// This is the Sealed Class your Repository will throw
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

// 1. Corresponds to 409 (Backend code: "resource_conflict")
class UserAlreadyExists extends AuthFailure {
  final String message;
  const UserAlreadyExists(this.message);
}

// 2. Corresponds to 404 (Backend code: "not_found")
class ResourcesExpired extends AuthFailure {
  final String message;
  const ResourcesExpired(this.message);
}

// 3. Corresponds to 400 (Backend code: "validation_error")
// message = top-level toast string (e.g. "Failed to send OTP via SMS: ...")
// errors  = field-specific hints (e.g. {'otp': ['Invalid OTP.']})
class InvalidInput extends AuthFailure {
  final String message;
  final Map<String, dynamic> errors;
  const InvalidInput(this.message, this.errors);
}

// 4. Corresponds to 401/403 (Backend code: "unauthorized")
class Unauthorized extends AuthFailure {
  final String message;
  const Unauthorized(this.message);
}

// 5. Fallback for 500 or parsing errors
class ServerError extends AuthFailure {
  final String message;
  const ServerError(this.message);
}
