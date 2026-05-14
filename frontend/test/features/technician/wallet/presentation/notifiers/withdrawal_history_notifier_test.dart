import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_history_page.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_request.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_status.dart';
import 'package:frontend/features/technician/wallet/domain/failures/withdrawal_failure.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/withdrawal_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/withdrawal_history_notifier.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';

class _MockRepo extends Mock implements WithdrawalRepository {}

WithdrawalRequest _row(int id, {String status = 'PENDING_REVIEW'}) =>
    WithdrawalRequest(
      id: id,
      amount: 500.0,
      status: WithdrawalStatus.fromWire(status),
      uiStatusLabel: 'Under review',
      payout: const PayoutDescriptor(
        kind: 'bank',
        label: 'HBL — Ali',
        masked: '••1234',
      ),
      adminExternalRef: '',
      requestedAt: DateTime.utc(2026, 5, 15),
      reviewedAt: null,
    );

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [withdrawalRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  test('build fetches page 1', () async {
    when(() => repo.listHistory(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row(1), _row(2)],
        nextCursor: 'abc',
      ),
    );

    final state = await container.read(withdrawalHistoryProvider.future);

    expect(state.page.results, hasLength(2));
    expect(state.page.nextCursor, 'abc');
    expect(state.page.hasMore, isTrue);
  });

  test('refresh re-fetches page 1', () async {
    when(() => repo.listHistory(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => WithdrawalHistoryPage(
              results: [_row(1)],
              nextCursor: null,
            ));

    await container.read(withdrawalHistoryProvider.future);
    await container.read(withdrawalHistoryProvider.notifier).refresh();

    verify(() => repo.listHistory(cursor: any(named: 'cursor')))
        .called(2);
  });

  test('loadMore appends and preserves existing rows', () async {
    when(() => repo.listHistory(cursor: null)).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row(1), _row(2)],
        nextCursor: 'page2',
      ),
    );
    when(() => repo.listHistory(cursor: 'page2')).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row(3), _row(4)],
        nextCursor: null,
      ),
    );

    await container.read(withdrawalHistoryProvider.future);
    await container.read(withdrawalHistoryProvider.notifier).loadMore();

    final state = container.read(withdrawalHistoryProvider).value!;
    expect(state.page.results.map((r) => r.id), [1, 2, 3, 4]);
    expect(state.page.nextCursor, isNull);
    expect(state.isLoadingMore, isFalse);
  });

  test('loadMore no-ops when nextCursor is null', () async {
    when(() => repo.listHistory(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row(1)],
        nextCursor: null,
      ),
    );

    await container.read(withdrawalHistoryProvider.future);
    await container.read(withdrawalHistoryProvider.notifier).loadMore();

    // Only the initial fetch happens; no second call.
    verify(() => repo.listHistory(cursor: null)).called(1);
    verifyNever(() => repo.listHistory(cursor: any(named: 'cursor')));
  });

  test(
      'loadMore preserves existing rows when the next page fetch fails',
      () async {
    when(() => repo.listHistory(cursor: null)).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row(1)],
        nextCursor: 'page2',
      ),
    );
    when(() => repo.listHistory(cursor: 'page2'))
        .thenThrow(const WithdrawalNetworkFailure());

    await container.read(withdrawalHistoryProvider.future);
    await container.read(withdrawalHistoryProvider.notifier).loadMore();

    final state = container.read(withdrawalHistoryProvider).value!;
    expect(state.page.results.map((r) => r.id), [1]); // existing row stays
    expect(state.isLoadingMore, isFalse);
  });

  test('fetch failure on first page surfaces as AsyncError', () async {
    when(() => repo.listHistory(cursor: any(named: 'cursor')))
        .thenThrow(const WithdrawalServerFailure());

    // Subscribe so the provider actually evaluates, then let
    // microtasks settle.
    final sub = container.listen(
      withdrawalHistoryProvider,
      (_, _) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().hasError, isTrue);
    sub.close();
  });
}
