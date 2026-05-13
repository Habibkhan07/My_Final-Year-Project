import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/topup_session.dart';
import 'package:frontend/features/technician/wallet/domain/entities/topup_status.dart';
import 'package:frontend/features/technician/wallet/domain/entities/topup_status_type.dart';
import 'package:frontend/features/technician/wallet/domain/failures/topup_failure.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/wallet_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/topup_notifier.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/topup_state.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';

class _MockRepo extends Mock implements WalletRepository {}

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [walletRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  group('start', () {
    test('idle → starting → awaitingGateway on success', () async {
      when(() => repo.startTopup(amountRs: 500)).thenAnswer(
        (_) async => const TopupSession(
          topupId: 42,
          redirectUrl: 'https://example.com/bridge?t=abc',
        ),
      );

      // Warm-up: read state once so the notifier builds.
      final initial = container.read(topupProvider);
      expect(initial.flow, TopupFlow.idle);

      await container.read(topupProvider.notifier).start(500);

      final state = container.read(topupProvider);
      expect(state.flow, TopupFlow.awaitingGateway);
      expect(state.session?.topupId, 42);
      expect(state.session?.redirectUrl,
          'https://example.com/bridge?t=abc');
      expect(state.failure, isNull);
    });

    test('TopupFailure during start → failed with failure populated',
        () async {
      when(() => repo.startTopup(amountRs: 500))
          .thenThrow(const TopupGatewayUnavailable());

      await container.read(topupProvider.notifier).start(500);

      final state = container.read(topupProvider);
      expect(state.flow, TopupFlow.failed);
      expect(state.failure, isA<TopupGatewayUnavailable>());
      expect(state.session, isNull);
    });

    test('double tap is no-op while in starting/awaitingGateway', () async {
      // First call: returns a session successfully, lands awaitingGateway.
      when(() => repo.startTopup(amountRs: 500)).thenAnswer(
        (_) async => const TopupSession(
          topupId: 1,
          redirectUrl: 'https://example.com/bridge?t=a',
        ),
      );
      await container.read(topupProvider.notifier).start(500);
      expect(container.read(topupProvider).flow, TopupFlow.awaitingGateway);

      // Second call while still in awaitingGateway: must be ignored.
      await container.read(topupProvider.notifier).start(1000);

      verify(() => repo.startTopup(amountRs: 500)).called(1);
      verifyNever(() => repo.startTopup(amountRs: 1000));
    });
  });

  group('onGatewayReturned → poll', () {
    setUp(() {
      when(() => repo.startTopup(amountRs: any(named: 'amountRs')))
          .thenAnswer(
        (_) async => const TopupSession(
          topupId: 7,
          redirectUrl: 'https://example.com/bridge?t=x',
        ),
      );
    });

    test('non-terminal poll keeps state in verifying', () async {
      when(() => repo.pollTopupStatus(topupId: 7)).thenAnswer(
        (_) async => TopupStatus(
          topupId: 7,
          status: TopupStatusType.redirected,
          amount: 500,
          gatewayName: 'mock',
          initiatedAt: DateTime.utc(2026, 5, 13),
          completedAt: null,
        ),
      );

      await container.read(topupProvider.notifier).start(500);
      container.read(topupProvider.notifier).onGatewayReturned();
      expect(container.read(topupProvider).flow, TopupFlow.verifying);

      await container.read(topupProvider.notifier).debugPollOnce(7);
      // Still verifying — a non-terminal poll schedules another attempt.
      expect(container.read(topupProvider).flow, TopupFlow.verifying);
    });

    test('terminal completed → success with status populated', () async {
      when(() => repo.pollTopupStatus(topupId: 7)).thenAnswer(
        (_) async => TopupStatus(
          topupId: 7,
          status: TopupStatusType.completed,
          amount: 500,
          gatewayName: 'mock',
          initiatedAt: DateTime.utc(2026, 5, 13),
          completedAt: DateTime.utc(2026, 5, 13, 10),
        ),
      );

      await container.read(topupProvider.notifier).start(500);
      container.read(topupProvider.notifier).onGatewayReturned();
      await container.read(topupProvider.notifier).debugPollOnce(7);

      final state = container.read(topupProvider);
      expect(state.flow, TopupFlow.success);
      expect(state.terminalStatus?.isSuccess, isTrue);
    });

    test('terminal failed status (gateway-side) → failed flow', () async {
      when(() => repo.pollTopupStatus(topupId: 7)).thenAnswer(
        (_) async => TopupStatus(
          topupId: 7,
          status: TopupStatusType.failed,
          amount: 500,
          gatewayName: 'mock',
          initiatedAt: DateTime.utc(2026, 5, 13),
          completedAt: null,
        ),
      );

      await container.read(topupProvider.notifier).start(500);
      container.read(topupProvider.notifier).onGatewayReturned();
      await container.read(topupProvider.notifier).debugPollOnce(7);

      expect(container.read(topupProvider).flow, TopupFlow.failed);
    });

    test('poll throwing TopupFailure → failed flow with failure populated',
        () async {
      when(() => repo.pollTopupStatus(topupId: 7))
          .thenThrow(const TopupNetworkFailure());

      await container.read(topupProvider.notifier).start(500);
      container.read(topupProvider.notifier).onGatewayReturned();
      await container.read(topupProvider.notifier).debugPollOnce(7);

      final state = container.read(topupProvider);
      expect(state.flow, TopupFlow.failed);
      expect(state.failure, isA<TopupNetworkFailure>());
    });
  });

  group('onGatewayAborted', () {
    test('from awaitingGateway → failed with TopupUserAborted', () async {
      when(() => repo.startTopup(amountRs: 500)).thenAnswer(
        (_) async => const TopupSession(
          topupId: 9,
          redirectUrl: 'https://example.com/bridge?t=q',
        ),
      );
      await container.read(topupProvider.notifier).start(500);

      container.read(topupProvider.notifier).onGatewayAborted();

      final state = container.read(topupProvider);
      expect(state.flow, TopupFlow.failed);
      expect(state.failure, isA<TopupUserAborted>());
    });

    test('from idle is a no-op (defensive)', () {
      container.read(topupProvider.notifier).onGatewayAborted();
      expect(container.read(topupProvider).flow, TopupFlow.idle);
    });
  });

  group('reset', () {
    test('returns state to idle', () async {
      when(() => repo.startTopup(amountRs: 500))
          .thenThrow(const TopupGatewayUnavailable());
      await container.read(topupProvider.notifier).start(500);
      expect(container.read(topupProvider).flow, TopupFlow.failed);

      container.read(topupProvider.notifier).reset();
      expect(container.read(topupProvider).flow, TopupFlow.idle);
      expect(container.read(topupProvider).failure, isNull);
    });
  });
}
