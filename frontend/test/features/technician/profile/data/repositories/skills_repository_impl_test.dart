import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/profile/data/data_sources/skills_local_data_source.dart';
import 'package:frontend/features/technician/profile/data/data_sources/skills_remote_data_source.dart';
import 'package:frontend/features/technician/profile/data/models/available_service_model.dart';
import 'package:frontend/features/technician/profile/data/models/technician_skill_model.dart';
import 'package:frontend/features/technician/profile/data/repositories/skills_repository_impl.dart';
import 'package:frontend/features/technician/profile/domain/failures/skills_failure.dart';

class _MockRemote extends Mock implements SkillsRemoteDataSource {}

class _MockLocal extends Mock implements SkillsLocalDataSource {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SkillsRepositoryImpl repo;
  late _MockRemote remote;
  late _MockLocal local;
  late _MockSecureStorage secureStorage;

  const tToken = 'tok_123';
  const tModel = TechnicianSkillModel(
    id: 1,
    subServiceId: 5,
    subServiceName: 'AC Repair',
    subServiceIconName: 'ac',
    isFixedPrice: false,
    parentServiceId: 2,
    parentServiceName: 'HVAC',
    parentServiceIconName: 'hvac',
  );

  setUpAll(() {
    registerFallbackValue(<TechnicianSkillModel>[tModel]);
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    secureStorage = _MockSecureStorage();
    repo = SkillsRepositoryImpl(
      remote: remote,
      local: local,
      secureStorage: secureStorage,
    );

    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => tToken);
    when(() => local.cacheSkills(any())).thenAnswer((_) async {});
    when(() => local.clear()).thenAnswer((_) async {});
    // Default: cache is empty. Tests that exercise the merge path
    // override this with a specific cached list.
    when(() => local.getCachedSkills()).thenReturn(null);
  });

  // -------------------------------------------------------------------------
  // listMySkills — offline-first
  // -------------------------------------------------------------------------

  group('listMySkills', () {
    test('returns entities and caches on remote success', () async {
      when(() => remote.listMySkills(tToken))
          .thenAnswer((_) async => const [tModel]);

      final result = await repo.listMySkills();

      expect(result, hasLength(1));
      expect(result.first.subService.name, 'AC Repair');
      verify(() => local.cacheSkills(const [tModel])).called(1);
    });

    test('falls back to cache on SocketException', () async {
      when(() => remote.listMySkills(tToken))
          .thenThrow(const SocketException('offline'));
      when(() => local.getCachedSkills()).thenReturn(const [tModel]);

      final result = await repo.listMySkills();

      expect(result.first.subService.name, 'AC Repair');
      verifyNever(() => local.cacheSkills(any()));
    });

    test('throws NetworkFailure when offline and cache empty', () async {
      when(() => remote.listMySkills(tToken))
          .thenThrow(const SocketException('offline'));
      when(() => local.getCachedSkills()).thenReturn(null);

      expect(repo.listMySkills(), throwsA(isA<SkillsNetworkFailure>()));
    });

    test('throws UnauthorizedFailure when token missing', () async {
      when(() => secureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      expect(repo.listMySkills(), throwsA(isA<SkillsUnauthorizedFailure>()));
      verifyNever(() => remote.listMySkills(any()));
    });

    test('maps 401 to UnauthorizedFailure', () async {
      when(() => remote.listMySkills(tToken)).thenThrow(
        const HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'Unauthorized.',
        ),
      );

      expect(repo.listMySkills(), throwsA(isA<SkillsUnauthorizedFailure>()));
    });

    test('maps 403 permission_denied to NotATechnicianFailure', () async {
      when(() => remote.listMySkills(tToken)).thenThrow(
        const HttpFailure(
          statusCode: 403,
          code: 'permission_denied',
          message: 'User is not a registered technician.',
        ),
      );

      expect(
        repo.listMySkills(),
        throwsA(isA<SkillsNotATechnicianFailure>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // addSkill — no optimistic cache write; cache invalidated on success
  // -------------------------------------------------------------------------

  group('addSkill', () {
    test('returns entity and merges new row into cache on success', () async {
      when(() => remote.addSkill(token: tToken, subServiceId: 5))
          .thenAnswer((_) async => tModel);
      // Empty cache pre-existing — the merge path writes a 1-element
      // list. Mock the getter explicitly so the repository's read of
      // the cache returns a known starting point.
      when(() => local.getCachedSkills()).thenReturn(const []);

      final result = await repo.addSkill(subServiceId: 5);

      expect(result.subService.id, 5);
      // Cache is no longer cleared on mutation — it's merged, so the
      // offline-after-add UX still works.
      verifyNever(() => local.clear());
      verify(() => local.cacheSkills(const [tModel])).called(1);
    });

    test('merge dedups against existing cached entry for same sub_service',
        () async {
      // Stale cache already has a row for sub_service 5 (e.g. another
      // device added it). The merge must replace, not duplicate.
      const stale = TechnicianSkillModel(
        id: 99,
        subServiceId: 5,
        subServiceName: 'Stale Name',
        subServiceIconName: null,
        isFixedPrice: false,
        parentServiceId: 2,
        parentServiceName: 'HVAC',
        parentServiceIconName: null,
      );
      when(() => local.getCachedSkills()).thenReturn(const [stale]);
      when(() => remote.addSkill(token: tToken, subServiceId: 5))
          .thenAnswer((_) async => tModel);

      await repo.addSkill(subServiceId: 5);

      // The cached write must be exactly [tModel] (id=1, fresh), not
      // [stale, tModel] — the wire model is the source of truth.
      verify(() => local.cacheSkills(const [tModel])).called(1);
    });

    test('maps 409 duplicate_skill to DuplicateFailure', () async {
      when(() => remote.addSkill(token: tToken, subServiceId: 5)).thenThrow(
        const HttpFailure(
          statusCode: 409,
          code: 'duplicate_skill',
          message: 'You already have this skill.',
        ),
      );

      expect(
        repo.addSkill(subServiceId: 5),
        throwsA(isA<SkillsDuplicateFailure>()),
      );
    });

    test('throws NetworkFailure on SocketException — never optimistic',
        () async {
      when(() => remote.addSkill(token: tToken, subServiceId: 5))
          .thenThrow(const SocketException('offline'));

      expect(
        repo.addSkill(subServiceId: 5),
        throwsA(isA<SkillsNetworkFailure>()),
      );
      // Critically: the cache must NOT be touched on the offline path —
      // neither cleared nor optimistically written. The user's existing
      // list survives until a successful round-trip.
      verifyNever(() => local.clear());
      verifyNever(() => local.cacheSkills(any()));
    });

    test('maps 403 category_not_allowed to CategoryNotAllowedFailure',
        () async {
      // Defence-in-depth: even though the FE picker filters categories,
      // the backend rejects category jumps independently. The envelope
      // carries `service_name` so the snackbar can name the category.
      when(() => remote.addSkill(token: tToken, subServiceId: 5)).thenThrow(
        const HttpFailure(
          statusCode: 403,
          code: 'category_not_allowed',
          message: "You don't work in HVAC yet.",
          errors: {
            'service_name': ['HVAC'],
          },
        ),
      );

      try {
        await repo.addSkill(subServiceId: 5);
        fail('expected throw');
      } on SkillsCategoryNotAllowedFailure catch (e) {
        expect(e.serviceName, 'HVAC');
        expect(e.message, "You don't work in HVAC yet.");
      }
    });

    test('category_not_allowed without service_name in envelope is tolerated',
        () async {
      // Contract drift defense: if the BE ever omits the field, we
      // still return SkillsCategoryNotAllowedFailure (so the screen
      // can render its specific UX), just with an empty serviceName.
      when(() => remote.addSkill(token: tToken, subServiceId: 5)).thenThrow(
        const HttpFailure(
          statusCode: 403,
          code: 'category_not_allowed',
          message: "You don't work in that category yet.",
        ),
      );

      try {
        await repo.addSkill(subServiceId: 5);
        fail('expected throw');
      } on SkillsCategoryNotAllowedFailure catch (e) {
        expect(e.serviceName, '');
      }
    });
  });

  // -------------------------------------------------------------------------
  // removeSkill
  // -------------------------------------------------------------------------

  group('removeSkill', () {
    test('drops row from cache on 204', () async {
      const otherRow = TechnicianSkillModel(
        id: 2,
        subServiceId: 6,
        subServiceName: 'Other',
        subServiceIconName: null,
        isFixedPrice: false,
        parentServiceId: 2,
        parentServiceName: 'HVAC',
        parentServiceIconName: null,
      );
      when(() => local.getCachedSkills())
          .thenReturn(const [tModel, otherRow]);
      when(() => remote.removeSkill(token: tToken, subServiceId: 5))
          .thenAnswer((_) async {});

      await repo.removeSkill(subServiceId: 5);

      // Cache must contain only the surviving row — no clear, no full
      // wipe. Preserving the rest of the list keeps the offline-after-
      // remove UX intact.
      verifyNever(() => local.clear());
      verify(() => local.cacheSkills(const [otherRow])).called(1);
    });

    test('no cache write when cache was empty', () async {
      when(() => local.getCachedSkills()).thenReturn(null);
      when(() => remote.removeSkill(token: tToken, subServiceId: 5))
          .thenAnswer((_) async {});

      await repo.removeSkill(subServiceId: 5);

      verifyNever(() => local.cacheSkills(any()));
      verifyNever(() => local.clear());
    });

    test('maps 400 last_skill_required to LastSkillFailure', () async {
      when(() => remote.removeSkill(token: tToken, subServiceId: 5))
          .thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'last_skill_required',
          message: 'You must keep at least one skill.',
        ),
      );

      expect(
        repo.removeSkill(subServiceId: 5),
        throwsA(isA<SkillsLastSkillFailure>()),
      );
    });

    test('maps 404 to ServerFailure (catch-all)', () async {
      when(() => remote.removeSkill(token: tToken, subServiceId: 5))
          .thenThrow(
        const HttpFailure(
          statusCode: 404,
          code: 'not_found',
          message: 'Skill not found.',
        ),
      );

      expect(
        repo.removeSkill(subServiceId: 5),
        throwsA(isA<SkillsServerFailure>()),
      );
    });

    test('throws NetworkFailure on SocketException', () async {
      when(() => remote.removeSkill(token: tToken, subServiceId: 5))
          .thenThrow(const SocketException('offline'));

      expect(
        repo.removeSkill(subServiceId: 5),
        throwsA(isA<SkillsNetworkFailure>()),
      );
      // Cache untouched on the offline path — same offline-preservation
      // contract as `addSkill`.
      verifyNever(() => local.clear());
      verifyNever(() => local.cacheSkills(any()));
    });
  });

  // -------------------------------------------------------------------------
  // listAvailableServices — picker catalog (licensed services only)
  // -------------------------------------------------------------------------

  group('listAvailableServices', () {
    test('returns entities on success', () async {
      const wireModel = AvailableServiceModel(
        id: 2,
        name: 'HVAC',
        iconName: 'hvac',
        subServices: [
          AvailableSubServiceModel(
            id: 5,
            name: 'AC Repair',
            iconName: 'ac',
            isFixedPrice: false,
          ),
        ],
      );
      when(() => remote.listAvailableServices(tToken))
          .thenAnswer((_) async => const [wireModel]);

      final result = await repo.listAvailableServices();

      expect(result, hasLength(1));
      expect(result.first.name, 'HVAC');
      expect(result.first.subServices.first.name, 'AC Repair');
    });

    test('throws NetworkFailure on SocketException', () async {
      when(() => remote.listAvailableServices(tToken))
          .thenThrow(const SocketException('offline'));

      expect(
        repo.listAvailableServices(),
        throwsA(isA<SkillsNetworkFailure>()),
      );
    });

    test('maps 401 to UnauthorizedFailure', () async {
      when(() => remote.listAvailableServices(tToken)).thenThrow(
        const HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'Unauthorized.',
        ),
      );

      expect(
        repo.listAvailableServices(),
        throwsA(isA<SkillsUnauthorizedFailure>()),
      );
    });
  });
}
