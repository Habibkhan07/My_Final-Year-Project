// Tests for the SkillsNotifier state machine.
//
// CLAUDE.md state-layer rule: no widget mounting, only ProviderContainer.
// Mocks the use cases (not the repo) since the notifier reads them
// directly via DI — this isolates the test to the state transitions
// the notifier itself owns.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/profile/domain/entities/technician_skill_entity.dart';
import 'package:frontend/features/technician/profile/domain/failures/skills_failure.dart';
import 'package:frontend/features/technician/profile/domain/use_cases/add_skill_use_case.dart';
import 'package:frontend/features/technician/profile/domain/use_cases/list_my_skills_use_case.dart';
import 'package:frontend/features/technician/profile/domain/use_cases/remove_skill_use_case.dart';
import 'package:frontend/features/technician/profile/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/profile/presentation/providers/skills_notifier.dart';

class _MockListMySkills extends Mock implements ListMySkillsUseCase {}

class _MockAddSkill extends Mock implements AddSkillUseCase {}

class _MockRemoveSkill extends Mock implements RemoveSkillUseCase {}

void main() {
  late _MockListMySkills mockList;
  late _MockAddSkill mockAdd;
  late _MockRemoveSkill mockRemove;

  TechnicianSkillEntity buildSkill({
    int id = 1,
    int subId = 5,
    String subName = 'AC Repair',
    String serviceName = 'HVAC',
  }) =>
      TechnicianSkillEntity(
        id: id,
        subService: SubServiceRef(
          id: subId,
          name: subName,
          iconName: 'icon',
          isFixedPrice: false,
          service: ParentServiceRef(
            id: 2,
            name: serviceName,
            iconName: 'svc_icon',
          ),
        ),
      );

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        listMySkillsUseCaseProvider.overrideWithValue(mockList),
        addSkillUseCaseProvider.overrideWithValue(mockAdd),
        removeSkillUseCaseProvider.overrideWithValue(mockRemove),
      ],
    );
  }

  setUp(() {
    mockList = _MockListMySkills();
    mockAdd = _MockAddSkill();
    mockRemove = _MockRemoveSkill();
  });

  // -------------------------------------------------------------------------
  // build
  // -------------------------------------------------------------------------

  group('build', () {
    test('resolves to AsyncData on use-case success', () async {
      final skills = [buildSkill()];
      when(() => mockList.call()).thenAnswer((_) async => skills);

      final c = makeContainer();
      addTearDown(c.dispose);

      final result = await c.read(skillsProvider.future);

      expect(result, skills);
      verify(() => mockList.call()).called(1);
    });

    test('resolves to AsyncError when use case throws', () async {
      when(() => mockList.call()).thenAnswer(
        (_) async {
          // Yield to the microtask queue so the build's awaited future
          // does not throw synchronously — Riverpod is happier with
          // errors that land after one event loop tick.
          await Future<void>.delayed(Duration.zero);
          throw const SkillsNetworkFailure('offline');
        },
      );

      final c = makeContainer();
      addTearDown(c.dispose);

      // Listener pattern (mirrors customer profile_notifier_test.dart):
      // capture the AsyncLoading → AsyncError transition through a
      // listener rather than awaiting `.future`, which lets the
      // build's internal future error out cleanly without involving
      // the test's own future chain. Riverpod surfaces a build-time
      // throw as an AsyncValue with hasError=true; the runtime class
      // can be AsyncError (settled) or AsyncLoading carrying the
      // prior error — both satisfy the contract.
      final transitions = <AsyncValue<List<TechnicianSkillEntity>>>[];
      c.listen(skillsProvider, (_, next) => transitions.add(next));

      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
        if (transitions.any((s) => s.hasError)) break;
      }

      expect(transitions.last.hasError, isTrue);
      expect(transitions.last.error, isA<SkillsNetworkFailure>());
    });
  });

  // -------------------------------------------------------------------------
  // addSkill
  // -------------------------------------------------------------------------

  group('addSkill', () {
    test('returns AsyncData and merges row into list (sorted)', () async {
      final initial = [
        buildSkill(id: 10, subId: 50, subName: 'Coil Clean'),
      ];
      when(() => mockList.call()).thenAnswer((_) async => initial);

      final added = buildSkill(id: 11, subId: 51, subName: 'Inverter Repair');
      when(() => mockAdd.call(subServiceId: 51))
          .thenAnswer((_) async => added);

      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(skillsProvider.future); // warm

      final result = await c
          .read(skillsProvider.notifier)
          .addSkill(subServiceId: 51);

      expect(result.hasValue, isTrue);
      expect(result.requireValue.subService.id, 51);

      final state = c.read(skillsProvider).value!;
      expect(state, hasLength(2));
      // Same parent service ('HVAC') so secondary sort is sub-service
      // name asc: Coil Clean < Inverter Repair.
      expect(state.map((s) => s.subService.name).toList(),
          ['Coil Clean', 'Inverter Repair']);
    });

    test('returns AsyncError and preserves list on failure', () async {
      final initial = [buildSkill(id: 10, subId: 50)];
      when(() => mockList.call()).thenAnswer((_) async => initial);
      when(() => mockAdd.call(subServiceId: 99))
          .thenThrow(const SkillsDuplicateFailure());

      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(skillsProvider.future);

      final result = await c
          .read(skillsProvider.notifier)
          .addSkill(subServiceId: 99);

      // AsyncValue.guard catches the throw — caller sees AsyncError.
      expect(result.hasError, isTrue);
      expect(result.error, isA<SkillsDuplicateFailure>());
      // List state is preserved across the failed mutation.
      expect(c.read(skillsProvider).value, initial);
    });
  });

  // -------------------------------------------------------------------------
  // removeSkill
  // -------------------------------------------------------------------------

  group('removeSkill', () {
    test('returns AsyncData and drops row by sub_service id', () async {
      final initial = [
        buildSkill(id: 10, subId: 50, subName: 'A'),
        buildSkill(id: 11, subId: 51, subName: 'B'),
      ];
      when(() => mockList.call()).thenAnswer((_) async => initial);
      when(() => mockRemove.call(subServiceId: 50))
          .thenAnswer((_) async {});

      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(skillsProvider.future);

      final result = await c
          .read(skillsProvider.notifier)
          .removeSkill(subServiceId: 50);

      expect(result.hasValue, isTrue);
      final state = c.read(skillsProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.subService.id, 51);
    });

    test('returns AsyncError and preserves list on LastSkillFailure',
        () async {
      final initial = [buildSkill(id: 10, subId: 50)];
      when(() => mockList.call()).thenAnswer((_) async => initial);
      when(() => mockRemove.call(subServiceId: 50))
          .thenThrow(const SkillsLastSkillFailure());

      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(skillsProvider.future);

      final result = await c
          .read(skillsProvider.notifier)
          .removeSkill(subServiceId: 50);

      expect(result.hasError, isTrue);
      expect(result.error, isA<SkillsLastSkillFailure>());
      expect(c.read(skillsProvider).value, initial);
    });
  });
}
