import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/work_location/data/data_sources/work_location_remote_data_source.dart';
import 'package:frontend/features/technician/work_location/data/models/work_location_model.dart';
import 'package:frontend/features/technician/work_location/data/repositories/work_location_repository_impl.dart';
import 'package:frontend/features/technician/work_location/domain/failures/work_location_failure.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements IWorkLocationRemoteDataSource {}

void main() {
  late MockRemote remote;
  late WorkLocationRepositoryImpl repo;

  setUp(() {
    remote = MockRemote();
    repo = WorkLocationRepositoryImpl(remote);
  });

  const tModel = WorkLocationModel(
    isSet: true,
    maxTravelRadiusKm: 12,
    latitude: 31.5204,
    longitude: 74.3587,
    workAddressLabel: 'Gulberg, Lahore',
  );

  group('getWorkLocation', () {
    test('returns entity on 200', () async {
      when(() => remote.getWorkLocation()).thenAnswer((_) async => tModel);

      final entity = await repo.getWorkLocation();

      expect(entity.isSet, true);
      expect(entity.latitude, 31.5204);
      expect(entity.workAddressLabel, 'Gulberg, Lahore');
    });

    test('maps SocketException -> WorkLocationNetworkFailure', () async {
      when(() => remote.getWorkLocation())
          .thenThrow(const SocketException('no net'));

      expect(
        () => repo.getWorkLocation(),
        throwsA(isA<WorkLocationNetworkFailure>()),
      );
    });

    test('maps 401 HttpFailure -> WorkLocationUnauthorizedFailure', () async {
      when(() => remote.getWorkLocation()).thenThrow(
        const HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'unauth',
        ),
      );

      expect(
        () => repo.getWorkLocation(),
        throwsA(isA<WorkLocationUnauthorizedFailure>()),
      );
    });

    test('maps 5xx HttpFailure -> WorkLocationServerFailure', () async {
      when(() => remote.getWorkLocation()).thenThrow(
        const HttpFailure(
          statusCode: 500,
          code: 'server_error',
          message: 'boom',
        ),
      );

      expect(
        () => repo.getWorkLocation(),
        throwsA(isA<WorkLocationServerFailure>()),
      );
    });

    test('maps FormatException -> WorkLocationParsingFailure', () async {
      when(() => remote.getWorkLocation())
          .thenThrow(const FormatException('bad json'));

      expect(
        () => repo.getWorkLocation(),
        throwsA(isA<WorkLocationParsingFailure>()),
      );
    });
  });

  group('saveWorkLocation', () {
    test('200 returns mapped entity', () async {
      when(() => remote.patchWorkLocation(any()))
          .thenAnswer((_) async => tModel);

      final entity = await repo.saveWorkLocation(
        latitude: 31.5204,
        longitude: 74.3587,
        maxTravelRadiusKm: 12,
        workAddressLabel: 'Gulberg, Lahore',
      );

      expect(entity.isSet, true);
      expect(entity.maxTravelRadiusKm, 12);
    });

    test('passes radius only when non-null in payload', () async {
      when(() => remote.patchWorkLocation(any()))
          .thenAnswer((_) async => tModel);

      await repo.saveWorkLocation(latitude: 1, longitude: 2);

      final captured = verify(
        () => remote.patchWorkLocation(captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(captured.containsKey('max_travel_radius_km'), false);
      expect(captured['latitude'], 1);
      expect(captured['longitude'], 2);
      // Label key is always present so backend can clear it on null.
      expect(captured.containsKey('work_address_label'), true);
    });

    test('404 -> WorkLocationProfileMissingFailure', () async {
      when(() => remote.patchWorkLocation(any())).thenThrow(
        const HttpFailure(
          statusCode: 404,
          code: 'not_found',
          message: 'no profile',
        ),
      );

      expect(
        () => repo.saveWorkLocation(latitude: 1, longitude: 2),
        throwsA(isA<WorkLocationProfileMissingFailure>()),
      );
    });

    test('400 with errors map surfaces field name', () async {
      when(() => remote.patchWorkLocation(any())).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'invalid',
          errors: {
            'latitude': ['Ensure this value is less than 90.'],
          },
        ),
      );

      expect(
        () => repo.saveWorkLocation(latitude: 999, longitude: 2),
        throwsA(
          isA<WorkLocationValidationFailure>().having(
            (f) => f.message,
            'message',
            contains('latitude:'),
          ),
        ),
      );
    });

    test('SocketException -> WorkLocationNetworkFailure', () async {
      when(() => remote.patchWorkLocation(any()))
          .thenThrow(const SocketException('no net'));

      expect(
        () => repo.saveWorkLocation(latitude: 1, longitude: 2),
        throwsA(isA<WorkLocationNetworkFailure>()),
      );
    });
  });
}
