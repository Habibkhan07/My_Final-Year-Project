import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:frontend/features/technician/wallet/data/models/wallet_balance_model.dart';
import 'package:frontend/features/technician/wallet/data/models/wallet_transaction_model.dart';
import 'package:frontend/features/technician/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:frontend/features/technician/wallet/domain/failures/wallet_failure.dart';

class _MockRemoteDataSource extends Mock implements IWalletRemoteDataSource {}

void main() {
  late WalletRepositoryImpl repo;
  late _MockRemoteDataSource mockRemote;

  setUp(() {
    mockRemote = _MockRemoteDataSource();
    repo = WalletRepositoryImpl(remoteDataSource: mockRemote);
  });

  test('happy path → WalletState entity', () async {
    when(() => mockRemote.getBalance()).thenAnswer(
      (_) async => const WalletBalanceModel(
        balance: '1500.00',
        asOf: '2026-05-13T22:30:00Z',
      ),
    );

    final state = await repo.getBalance();

    expect(state.balance, 1500.00);
    expect(state.asOf.year, 2026);
  });

  test('HttpFailure 401 → WalletPermissionFailure', () async {
    when(() => mockRemote.getBalance()).thenThrow(
      const HttpFailure(
        statusCode: 401,
        code: 'permission_denied',
        message: 'No',
      ),
    );

    await expectLater(repo.getBalance(), throwsA(isA<WalletPermissionFailure>()));
  });

  test('HttpFailure 403 → WalletPermissionFailure', () async {
    when(() => mockRemote.getBalance()).thenThrow(
      const HttpFailure(statusCode: 403, code: 'forbidden', message: 'No'),
    );

    await expectLater(repo.getBalance(), throwsA(isA<WalletPermissionFailure>()));
  });

  test('HttpFailure 500 → WalletServerFailure', () async {
    when(() => mockRemote.getBalance()).thenThrow(
      const HttpFailure(statusCode: 500, code: 'server_error', message: 'oops'),
    );

    await expectLater(repo.getBalance(), throwsA(isA<WalletServerFailure>()));
  });

  test('SocketException → WalletNetworkFailure (NO cache fallback)', () async {
    when(() => mockRemote.getBalance())
        .thenThrow(const SocketException('offline'));

    await expectLater(repo.getBalance(), throwsA(isA<WalletNetworkFailure>()));
  });

  test('FormatException → WalletServerFailure', () async {
    when(() => mockRemote.getBalance())
        .thenThrow(const FormatException('bad json'));

    await expectLater(repo.getBalance(), throwsA(isA<WalletServerFailure>()));
  });

  group('listTransactions', () {
    const emptyPage = WalletTransactionPageModel(
      results: [],
      nextCursor: null,
    );

    test('happy path → WalletTransactionPage entity', () async {
      when(() => mockRemote.listTransactions(cursor: null))
          .thenAnswer((_) async => emptyPage);

      final page = await repo.listTransactions();

      expect(page.results, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('passes through the cursor', () async {
      when(() => mockRemote.listTransactions(cursor: 'C1'))
          .thenAnswer((_) async => emptyPage);

      await repo.listTransactions(cursor: 'C1');

      verify(() => mockRemote.listTransactions(cursor: 'C1')).called(1);
    });

    test('HttpFailure 401 → WalletPermissionFailure', () async {
      when(() => mockRemote.listTransactions(cursor: any(named: 'cursor')))
          .thenThrow(
        const HttpFailure(statusCode: 401, code: 'permission_denied', message: 'No'),
      );

      await expectLater(
        repo.listTransactions(),
        throwsA(isA<WalletPermissionFailure>()),
      );
    });

    test('HttpFailure 400 (bad cursor) → WalletServerFailure', () async {
      when(() => mockRemote.listTransactions(cursor: any(named: 'cursor')))
          .thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid cursor.',
        ),
      );

      await expectLater(
        repo.listTransactions(cursor: 'bad'),
        throwsA(isA<WalletServerFailure>()),
      );
    });

    test('SocketException → WalletNetworkFailure', () async {
      when(() => mockRemote.listTransactions(cursor: any(named: 'cursor')))
          .thenThrow(const SocketException('offline'));

      await expectLater(
        repo.listTransactions(),
        throwsA(isA<WalletNetworkFailure>()),
      );
    });
  });
}
