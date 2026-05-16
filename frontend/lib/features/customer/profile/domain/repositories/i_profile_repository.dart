import '../entities/customer_profile_entity.dart';

/// Repository contract for the authenticated user's profile.
///
/// Throws [ProfileNetworkFailure] when offline AND no cache,
/// [ProfileServerFailure] for non-2xx non-401 (`errors` map carries
/// field-level details), [ProfileUnauthorizedFailure] on 401, and
/// [ProfileParsingFailure] on malformed JSON.
abstract class IProfileRepository {
  /// Returns the caller's profile.
  /// Offline-first: falls back to the local cache on `SocketException`.
  Future<CustomerProfileEntity> getMe();

  /// Updates first/last name. Both required (backend serializer enforces).
  /// Returns the post-update state — same shape as `getMe()`.
  Future<CustomerProfileEntity> updateMe({
    required String firstName,
    required String lastName,
  });
}
