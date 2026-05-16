/// Sealed failure hierarchy for the technician skills feature.
///
/// Mirrors the customer-side `ProfileFailure` shape (see
/// `features/customer/profile/domain/failures/profile_failure.dart`)
/// so the two surfaces feel identical when something goes wrong.
/// Repository methods throw a subclass of this; the presentation
/// layer pattern-matches exhaustively, so a new failure type is a
/// compile error at every consumer until handled.
///
/// `toString()` returns only the human-readable message — a stray
/// `error.toString()` in a snackbar never leaks the Dart class name.
sealed class SkillsFailure implements Exception {
  final String message;
  const SkillsFailure(this.message);

  @override
  String toString() => message;
}

/// `SocketException` from the data source AND no usable local cache.
class SkillsNetworkFailure extends SkillsFailure {
  const SkillsNetworkFailure([
    super.message = 'No internet connection. Please check your settings.',
  ]);
}

/// 401 from the backend — the cached token is dead. The presentation
/// layer should respond by triggering a forced sign-out (auth
/// notifier's `logout()` is idempotent).
class SkillsUnauthorizedFailure extends SkillsFailure {
  const SkillsUnauthorizedFailure([
    super.message = 'Session expired. Please sign in again.',
  ]);
}

/// 403 from the backend — the user is authenticated but is not a
/// technician. Should never happen in practice (the profile tab only
/// renders inside the tech shell), but the contract has the case so
/// the UI can fail gracefully rather than crash.
class SkillsNotATechnicianFailure extends SkillsFailure {
  const SkillsNotATechnicianFailure([
    super.message = 'Your account is not registered as a technician.',
  ]);
}

/// 409 `duplicate_skill` — the tech already holds this sub-service.
/// The Add Skill screen filters out duplicates client-side (best-
/// effort — `skillsProvider.value` may be null on a cold-start picker),
/// so the backend is the source of truth and this surfaces when the
/// client-side filter is stale or hasn't populated yet.
class SkillsDuplicateFailure extends SkillsFailure {
  const SkillsDuplicateFailure([
    super.message = 'You already have this skill.',
  ]);
}

/// 400 `last_skill_required` — removing the targeted skill would
/// drop the tech to zero skills, which makes them invisible to the
/// matchmaker. The UX nudge: "add a new one before removing this".
class SkillsLastSkillFailure extends SkillsFailure {
  const SkillsLastSkillFailure([
    super.message = 'You must keep at least one skill. '
        'Add a new skill before removing this one.',
  ]);
}

/// 403 `category_not_allowed` — the tech tried to add a sub-service
/// under a parent service they don't currently have any skill in. The
/// picker filters categories client-side (only services the tech has
/// active skills under are listed), but the backend is the source of
/// truth and rejects category jumps independently.
///
/// "Category" here = parent `Service`. The gate's anchor is the set
/// of parent services covered by the tech's current `TechnicianSkill`
/// rows. Onboarding requires `>= 1` skill and the remove path enforces
/// `>= 1` forever, so the set is always non-empty.
///
/// Carries [serviceName] so the snackbar can name the category the
/// tech tried to jump into ("You don't work in HVAC yet. Contact
/// support to expand into new categories.").
class SkillsCategoryNotAllowedFailure extends SkillsFailure {
  /// The display name of the parent service the tech tried to add a
  /// sub-service under (e.g. "HVAC", "Plumbing"). Empty when the
  /// backend envelope did not carry the field — the message string
  /// then stands alone.
  final String serviceName;

  const SkillsCategoryNotAllowedFailure(
    super.message, {
    this.serviceName = '',
  });
}

/// Catch-all for non-2xx responses not covered above. Carries the
/// envelope's `errors` map for downstream consumers (currently unused
/// since the skills surface has no per-field inputs, but the contract
/// is shaped for the future).
class SkillsServerFailure extends SkillsFailure {
  final Map<String, dynamic> errors;
  const SkillsServerFailure(super.message, [this.errors = const {}]);
}

/// Malformed JSON / unexpected wire shape. Distinct from
/// [SkillsServerFailure] so a contract drift can be diagnosed
/// separately from a backend rejection.
class SkillsParsingFailure extends SkillsFailure {
  const SkillsParsingFailure([
    super.message = 'Failed to read skills data.',
  ]);
}
