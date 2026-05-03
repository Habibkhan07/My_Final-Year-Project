import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/mappers/system_event_mapper.dart';
import 'package:frontend/core/realtime/data/models/system_event_model.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_type.dart';
import 'package:frontend/core/realtime/domain/entities/target_role.dart';

void main() {
  group('SystemEventMapper', () {
    test('fromJson + toJson byte-equal round-trip', () {
      // After flag #19 the model gained two optional envelope fields
      // (`expires_at`, `recipient_user_id`). On round-trip, json_serializable
      // emits them as null when absent on the input — that's the expected
      // wire shape during the rollout window when older backends don't
      // populate them. Newer backends will send non-null values which round-
      // trip identically.
      final input = {
        'kind': 'event',
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'rawType': 'job_new_request',
        'targetRole': 'technician',
        'timestamp': '2023-01-01T12:00:00.000Z',
        'payload': {'key': 'value'},
      };
      final expected = {
        ...input,
        'expires_at': null,
        'recipient_user_id': null,
      };

      final model = SystemEventModel.fromJson(input);
      final result = model.toJson();

      expect(result, equals(expected));
    });

    test(
      'fromJson + toJson round-trip with envelope-level expires_at + '
      'recipient_user_id (flag #19 fully populated)',
      () {
        final json = {
          'kind': 'event',
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'rawType': 'job_new_request',
          'targetRole': 'technician',
          'timestamp': '2023-01-01T12:00:00.000Z',
          'payload': {'key': 'value'},
          'expires_at': '2023-01-01T12:05:00.000Z',
          'recipient_user_id': 42,
        };

        final model = SystemEventModel.fromJson(json);
        expect(model.expiresAt, '2023-01-01T12:05:00.000Z');
        expect(model.recipientUserId, 42);

        // Bidirectional round-trip preserves both new fields.
        expect(model.toJson(), equals(json));
      },
    );

    test('fromJson without kind throws (required field, fail loudly)', () {
      // Backend wire contract guarantees kind on every frame post-streams
      // patch. A missing kind should crash at deserialization rather than
      // silently enter the event pipeline as ambiguous data.
      final json = {
        'id': '123',
        'rawType': 'job_new_request',
        'targetRole': 'technician',
        'timestamp': '2023-01-01T12:00:00.000Z',
        'payload': <String, dynamic>{},
      };

      expect(() => SystemEventModel.fromJson(json), throwsA(anything));
    });

    test('toDomain happy path', () {
      final model = const SystemEventModel(
        kind: 'event',
        id: '123',
        rawType: 'job_new_request',
        targetRole: 'technician',
        timestamp: '2023-01-01T12:00:00.000Z',
        payload: {'key': 'value'},
      );

      final entity = model.toDomain();

      expect(entity, isNotNull);
      expect(entity!.id, equals('123'));
      expect(entity.rawType, equals('job_new_request'));
      expect(entity.eventType, equals(SystemEventType.jobNewRequest));
      expect(entity.targetRole, equals(TargetRole.technician));
      expect(entity.timestamp, equals(DateTime.parse('2023-01-01T12:00:00.000Z')));
      expect(entity.payload, equals({'key': 'value'}));
    });

    test('toDomain with malformed timestamp returns null', () {
      final model = const SystemEventModel(
        kind: 'event',
        id: '123',
        rawType: 'job_new_request',
        targetRole: 'technician',
        timestamp: 'not-a-date',
        payload: {},
      );

      final entity = model.toDomain();

      expect(entity, isNull);
    });

    test('toDomain with unknown rawType returns entity with eventType=unknown', () {
      final model = const SystemEventModel(
        kind: 'event',
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
        kind: 'event',
        id: '123',
        rawType: 'job_new_request',
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
