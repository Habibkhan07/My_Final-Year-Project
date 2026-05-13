import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:frontend/features/technician/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:frontend/features/technician/wallet/data/models/wallet_balance_model.dart';
import 'package:frontend/features/technician/wallet/data/models/wallet_transaction_model.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late WalletRemoteDataSource dataSource;
  late _MockHttpClient mockClient;
  late _MockAuthLocalDataSource mockAuth;

  setUp(() {
    mockClient = _MockHttpClient();
    mockAuth = _MockAuthLocalDataSource();
    dataSource = WalletRemoteDataSource(
      client: mockClient,
      authLocalDataSource: mockAuth,
    );
    registerFallbackValue(Uri());
  });

  final happyBody = jsonEncode({
    'balance': '1500.00',
    'as_of': '2026-05-13T22:30:00Z',
  });

  group('getBalance', () {
    test('200 → parses into WalletBalanceModel', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 'tok');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(happyBody, 200));

      final result = await dataSource.getBalance();

      expect(result, isA<WalletBalanceModel>());
      expect(result.balance, '1500.00');
      expect(result.asOf, '2026-05-13T22:30:00Z');
    });

    test('sends Authorization header when token present', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 'abc');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(happyBody, 200));

      await dataSource.getBalance();

      final captured = verify(
        () => mockClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      expect(captured.last, containsPair('Authorization', 'Token abc'));
    });

    test('401 → throws HttpFailure with code from body', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => null);
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'code': 'permission_denied',
                  'message': 'Bad token',
                }),
                401,
              ));

      await expectLater(
        dataSource.getBalance(),
        throwsA(
          isA<HttpFailure>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.code, 'code', 'permission_denied'),
        ),
      );
    });

    test('500 → throws HttpFailure server_error', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('upstream blew up', 500));

      await expectLater(
        dataSource.getBalance(),
        throwsA(
          isA<HttpFailure>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('SocketException propagates (repository turns it into NetworkFailure)',
        () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('offline'));

      await expectLater(
        dataSource.getBalance(),
        throwsA(isA<SocketException>()),
      );
    });
  });

  final txPageBody = jsonEncode({
    'next_cursor': 'CURSOR_XYZ',
    'results': [
      {
        'id': 42,
        'type': 'COMMISSION_DEBIT',
        'amount': '-200.00',
        'balance_after': '800.00',
        'timestamp': '2026-05-13T12:00:00Z',
        'memo': '',
        'ui_icon': 'commission',
        'ui_title': 'Platform commission',
        'ui_subtitle': 'Booking #128',
        'ui_amount_color': 'debit',
      },
    ],
  });

  group('listTransactions', () {
    test('200 → parses into WalletTransactionPageModel with rows', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 'tok');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(txPageBody, 200));

      final result = await dataSource.listTransactions();

      expect(result, isA<WalletTransactionPageModel>());
      expect(result.results.length, 1);
      final row = result.results.first;
      expect(row.id, 42);
      expect(row.amount, '-200.00');
      expect(row.uiIcon, 'commission');
      expect(row.uiAmountColor, 'debit');
      expect(result.nextCursor, 'CURSOR_XYZ');
    });

    test('appends ?cursor= when supplied', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(txPageBody, 200));

      await dataSource.listTransactions(cursor: 'PREV_CURSOR');

      final captured = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters['cursor'], 'PREV_CURSOR');
    });

    test('omits cursor query param when null', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(txPageBody, 200));

      await dataSource.listTransactions();

      final captured = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters.containsKey('cursor'), isFalse);
    });

    test('401 → throws HttpFailure permission_denied', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => null);
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({'code': 'permission_denied', 'message': 'No'}),
                401,
              ));

      await expectLater(
        dataSource.listTransactions(),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.code, 'code', 'permission_denied')),
      );
    });

    test('400 invalid cursor → throws HttpFailure validation_error', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({'code': 'validation_error', 'message': 'Bad cursor'}),
                400,
              ));

      await expectLater(
        dataSource.listTransactions(cursor: 'bad'),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.code, 'code', 'validation_error')),
      );
    });

    test('SocketException propagates to repository layer', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('offline'));

      await expectLater(
        dataSource.listTransactions(),
        throwsA(isA<SocketException>()),
      );
    });
  });
}
