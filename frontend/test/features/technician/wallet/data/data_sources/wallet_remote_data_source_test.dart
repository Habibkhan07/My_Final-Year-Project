import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:frontend/features/technician/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:frontend/features/technician/wallet/data/models/wallet_balance_model.dart';

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
}
