import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/data/mappers/system_event_mapper.dart';
import 'package:frontend/core/data/models/system_event_model.dart';
import 'package:frontend/core/domain/entities/system_event_type.dart';
import 'package:frontend/core/domain/entities/target_role.dart';

void main() {
  group('SystemEventMapper', () {
    test('fromJson + toJson byte-equal round-trip', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'rawType': 'job_dispatched',
        'targetRole': 'technician',
        'timestamp': '2023-01-01T12:00:00.000Z',
        'payload': {'key': 'value'},
      };

      final model = SystemEventModel.fromJson(json);
      final result = model.toJson();

      expect(result, equals(json));
    });

    test('toDomain happy path', () {
      final model = const SystemEventModel(
        id: '123',
        rawType: 'job_dispatched',
        targetRole: 'technician',
        timestamp: '2023-01-01T12:00:00.000Z',
        payload: {'key': 'value'},
      );

      final entity = model.toDomain();

      expect(entity, isNotNull);
      expect(entity!.id, equals('123'));
      expect(entity.rawType, equals('job_dispatched'));
      expect(entity.eventType, equals(SystemEventType.jobDispatched));
      expect(entity.targetRole, equals(TargetRole.technician));
      expect(entity.timestamp, equals(DateTime.parse('2023-01-01T12:00:00.000Z')));
      expect(entity.payload, equals({'key': 'value'}));
    });

    test('toDomain with malformed timestamp returns null', () {
      final model = const SystemEventModel(
        id: '123',
        rawType: 'job_dispatched',
        targetRole: 'technician',
        timestamp: 'not-a-date',
        payload: {},
      );

      final entity = model.toDomain();

      expect(entity, isNull);
    });

    test('toDomain with unknown rawType returns entity with eventType=unknown', () {
      final model = const SystemEventModel(
        id: '123',
        rawType: 'something_new_backend_added_v3',
        targetRole: 'technician',
        timestamp: '2023-01-01T12:00:00.000Z',
        payload: {},
      );

      final entity = model.toDomain();

      expect(entity, isNotNull);
      expect(entity!.eventType, equals(SystemEventType.unknown));
      expect(entity.rawType, equals('something_new_backend_added_v3'));
    });

    test('toDomain with unknown targetRole string returns entity (lenient default)', () {
      final model = const SystemEventModel(
        id: '123',
        rawType: 'job_dispatched',
        targetRole: 'admin',
        timestamp: '2023-01-01T12:00:00.000Z',
        payload: {},
      );

      final entity = model.toDomain();

      expect(entity, isNotNull);
      expect(entity!.targetRole, equals(TargetRole.customer)); // Default is customer
    });
  });
}
