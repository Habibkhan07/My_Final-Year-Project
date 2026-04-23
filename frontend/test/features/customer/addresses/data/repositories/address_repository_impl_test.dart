import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/addresses/data/data_sources/address_local_data_source.dart';
import 'package:frontend/features/customer/addresses/data/data_sources/address_location_data_source.dart';
import 'package:frontend/features/customer/addresses/data/data_sources/address_remote_data_source.dart';
import 'package:frontend/features/customer/addresses/data/models/address_model.dart';
import 'package:frontend/features/customer/addresses/data/repositories/address_repository_impl.dart';
import 'package:frontend/features/customer/addresses/domain/failures/address_failure.dart';

class MockRemoteDataSource extends Mock implements AddressRemoteDataSource {}

class MockLocalDataSource extends Mock implements AddressLocalDataSource {}

class MockLocationDataSource extends Mock implements AddressLocationDataSource {}

void main() {
  late AddressRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late MockLocationDataSource mockLocation;

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    mockLocation = MockLocationDataSource();
    repository = AddressRepositoryImpl(mockRemote, mockLocal, mockLocation);
    registerFallbackValue(const CreateAddressRequest(
      label: '',
      streetAddress: '',
      latitude: 0,
      longitude: 0,
      isDefault: false,
    ));
  });

  const tModel = CustomerAddressModel(
    id: 1,
    label: 'Home',
    streetAddress: '123 St',
    latitude: 31.0,
    longitude: 74.0,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  group('updateAddress', () {
    test('returns entity on success', () async {
      when(() => mockRemote.updateAddress(any(), any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.updateAddress(id: 1, isDefault: true);

      expect(result.id, 1);
      expect(result.isDefault, true);
      verify(() => mockRemote.updateAddress(1, {'is_default': true})).called(1);
    });

    test('propagates field errors from HttpFailure', () async {
      when(() => mockRemote.updateAddress(any(), any())).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Error',
          errors: {
            'is_default': ['Invalid value']
          },
        ),
      );

      expect(
        () => repository.updateAddress(id: 1, isDefault: true),
        throwsA(isA<AddressServerFailure>().having(
          (f) => f.message,
          'message',
          'is_default: Invalid value',
        )),
      );
    });

    test('throws AddressNetworkFailure on SocketException', () async {
      when(() => mockRemote.updateAddress(any(), any()))
          .thenThrow(const SocketException('no internet'));

      expect(
        () => repository.updateAddress(id: 1, isDefault: true),
        throwsA(isA<AddressNetworkFailure>()),
      );
    });
  });
}
