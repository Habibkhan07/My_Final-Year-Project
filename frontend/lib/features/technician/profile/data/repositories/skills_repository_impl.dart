import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/available_sub_service_entity.dart';
import '../../domain/entities/technician_skill_entity.dart';
import '../../domain/failures/skills_failure.dart';
import '../../domain/repositories/i_skills_repository.dart';
import '../data_sources/skills_local_data_source.dart';
import '../data_sources/skills_remote_data_source.dart';
import '../models/technician_skill_model.dart';

/// Single arbitration point between remote, local cache, and secure
/// storage (token). Implements the offline-first contract for
/// `listMySkills()` and the strict error-pipeline mapping for the
/// mutating operations.
class SkillsRepositoryImpl implements ISkillsRepository {
  final SkillsRemoteDataSource remote;
  final SkillsLocalDataSource local;
  final FlutterSecureStorage secureStorage;

  static const String _tokenKey = 'auth_token';

  SkillsRepositoryImpl({
    required this.remote,
    required this.local,
    required this.secureStorage,
  });

  Future<String> _requireToken() async {
    final token = await secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      throw const SkillsUnauthorizedFailure(
        'You are not signed in. Please sign in again.',
      );
    }
    return token;
  }

  @override
  Future<List<TechnicianSkillEntity>> listMySkills() async {
    try {
      final token = await _requireToken();
      final models = await remote.listMySkills(token);
      await local.cacheSkills(models);
      return models.map((m) => m.toEntity()).toList(growable: false);
    } on SocketException {
      final cached = local.getCachedSkills();
      if (cached != null) {
        return cached.map((m) => m.toEntity()).toList(growable: false);
      }
      throw const SkillsNetworkFailure();
    } on HttpFailure catch (e) {
      throw _mapHttp(e);
    } on FormatException {
      throw const SkillsParsingFailure();
    } on SkillsFailure {
      rethrow;
    } catch (e) {
      throw SkillsServerFailure(e.toString());
    }
  }

  @override
  Future<TechnicianSkillEntity> addSkill({required int subServiceId}) async {
    try {
      final token = await _requireToken();
      final model = await remote.addSkill(
        token: token,
        subServiceId: subServiceId,
      );
      // Merge into the cached list rather than clearing it. Clearing
      // would degrade the offline experience: if the user adds a skill
      // and then loses connectivity before any read, the next read
      // returns SkillsNetworkFailure with no cached fallback. Merging
      // keeps the offline-first contract intact across mutations.
      final existing = local.getCachedSkills() ?? const <TechnicianSkillModel>[];
      // Defensive dedup — the wire model is the source of truth, but
      // a stale cache could already contain the same sub_service_id
      // (e.g. another device added it). The server's unique_together
      // guarantees one row per (tech, sub_service), so the cache
      // should reflect the same invariant.
      final deduped = existing
          .where((m) => m.subServiceId != model.subServiceId)
          .toList(growable: true)
        ..add(model);
      await local.cacheSkills(deduped);
      return model.toEntity();
    } on SocketException {
      throw const SkillsNetworkFailure(
        'Cannot save changes while offline. Try again when connected.',
      );
    } on HttpFailure catch (e) {
      throw _mapHttp(e);
    } on FormatException {
      throw const SkillsParsingFailure();
    } on SkillsFailure {
      rethrow;
    } catch (e) {
      throw SkillsServerFailure(e.toString());
    }
  }

  @override
  Future<void> removeSkill({required int subServiceId}) async {
    try {
      final token = await _requireToken();
      await remote.removeSkill(token: token, subServiceId: subServiceId);
      // Drop the row from the cache rather than clearing the whole
      // list. Same offline-preservation reasoning as `addSkill`.
      final existing = local.getCachedSkills();
      if (existing != null) {
        final pruned = existing
            .where((m) => m.subServiceId != subServiceId)
            .toList(growable: false);
        await local.cacheSkills(pruned);
      }
    } on SocketException {
      throw const SkillsNetworkFailure(
        'Cannot save changes while offline. Try again when connected.',
      );
    } on HttpFailure catch (e) {
      throw _mapHttp(e);
    } on FormatException {
      throw const SkillsParsingFailure();
    } on SkillsFailure {
      rethrow;
    } catch (e) {
      throw SkillsServerFailure(e.toString());
    }
  }

  @override
  Future<List<AvailableServiceEntity>> listAvailableServices() async {
    try {
      final token = await _requireToken();
      final models = await remote.listAvailableServices(token);
      return models.map((m) => m.toEntity()).toList(growable: false);
    } on SocketException {
      // The Add Skill picker is online-only — there's no use-case for
      // adding a skill while offline (the POST would also fail), so
      // surfacing a network failure is the clean exit.
      throw const SkillsNetworkFailure(
        'Cannot load the service list while offline.',
      );
    } on HttpFailure catch (e) {
      throw _mapHttp(e);
    } on FormatException {
      throw const SkillsParsingFailure();
    } on SkillsFailure {
      rethrow;
    } catch (e) {
      throw SkillsServerFailure(e.toString());
    }
  }

  /// Maps the standard error envelope's `code` field onto the sealed
  /// domain failure hierarchy. Stays in lockstep with the backend's
  /// custom exception handler emissions.
  SkillsFailure _mapHttp(HttpFailure e) {
    switch (e.code) {
      case 'unauthorized':
        return SkillsUnauthorizedFailure(e.message);
      case 'permission_denied':
        return SkillsNotATechnicianFailure(e.message);
      case 'duplicate_skill':
        return SkillsDuplicateFailure(e.message);
      case 'last_skill_required':
        return SkillsLastSkillFailure(e.message);
      case 'category_not_allowed':
        // Pull the parent service name from the envelope's errors map
        // so the snackbar can name the category. The map shape is
        // `{"service_name": ["HVAC"]}`; fall back to empty if absent
        // so a contract drift doesn't crash the parser.
        final raw = e.errors['service_name'];
        final serviceName = (raw is List && raw.isNotEmpty)
            ? raw.first.toString()
            : '';
        return SkillsCategoryNotAllowedFailure(
          e.message,
          serviceName: serviceName,
        );
      default:
        return SkillsServerFailure(e.message, e.errors);
    }
  }
}
