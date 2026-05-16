import '../entities/available_sub_service_entity.dart';
import '../entities/technician_skill_entity.dart';

/// Repository contract for the technician profile's "My Skills" surface.
///
/// All methods throw a subclass of `SkillsFailure`:
///   * [SkillsNetworkFailure] when offline AND no cache,
///   * [SkillsUnauthorizedFailure] on 401 (forced sign-out),
///   * [SkillsNotATechnicianFailure] on 403 (should never happen in
///     the tech shell, included for completeness),
///   * [SkillsDuplicateFailure] on POST 409 `duplicate_skill`,
///   * [SkillsLastSkillFailure] on DELETE 400 `last_skill_required`,
///   * [SkillsServerFailure] for other non-2xx (with `errors` map),
///   * [SkillsParsingFailure] on malformed JSON.
abstract class ISkillsRepository {
  /// Offline-first list of the caller's current skills.
  Future<List<TechnicianSkillEntity>> listMySkills();

  /// Add a sub-service to the caller's skill set. Returns the freshly
  /// created row so the notifier can merge it into the cached list
  /// without a second `GET`. Mutations are never cached optimistically.
  Future<TechnicianSkillEntity> addSkill({required int subServiceId});

  /// Remove a sub-service from the caller's skill set. Throws
  /// [SkillsLastSkillFailure] if this would drop the tech to zero.
  Future<void> removeSkill({required int subServiceId});

  /// Service tree (with sub-services nested) for the Add Skill picker.
  /// Backed by `GET /api/technicians/onboarding/metadata/` — the
  /// onboarding-time endpoint is reused since both surfaces need
  /// exactly the same catalog data. No caching: the catalog changes
  /// rarely but the picker is a transient screen, fresh-read is fine.
  Future<List<AvailableServiceEntity>> listAvailableServices();
}
