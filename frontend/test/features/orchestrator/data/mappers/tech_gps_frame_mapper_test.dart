import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/tech_gps_frame_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/tech_gps_frame_model.dart';

void main() {
  group('TechGpsFrameMapper.toDomain', () {
    final fixedNow = DateTime.utc(2026, 5, 10, 14, 30, 12);
    DateTime injectedNow() => fixedNow;

    test('maps complete payload to domain entity with arrival timestamp', () {
      const model = TechGpsFrameModel(
        bookingId: 42,
        lat: 31.5204,
        lng: 74.3587,
        accuracyMeters: 8.5,
        heading: 145.0,
      );

      final entity = TechGpsFrameMapper.toDomain(model, now: injectedNow);

      expect(entity.bookingId, 42);
      expect(entity.latitude, 31.5204);
      expect(entity.longitude, 74.3587);
      expect(entity.accuracyMeters, 8.5);
      expect(entity.heading, 145.0);
      expect(entity.frameArrivedAt, fixedNow);
    });

    test(
      'preserves null accuracy / heading (stationary or low-quality fix)',
      () {
        const model = TechGpsFrameModel(bookingId: 42, lat: 31.5, lng: 74.3);

        final entity = TechGpsFrameMapper.toDomain(model, now: injectedNow);

        expect(entity.accuracyMeters, isNull);
        expect(entity.heading, isNull);
      },
    );

    test('uses DateTime.now when no injection provided', () {
      const model = TechGpsFrameModel(bookingId: 42, lat: 31.5, lng: 74.3);

      final before = DateTime.now();
      final entity = TechGpsFrameMapper.toDomain(model);
      final after = DateTime.now();

      expect(
        entity.frameArrivedAt.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        entity.frameArrivedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('TechGpsFrameModel.fromJson (wire contract regression)', () {
    test('parses the backend\'s tech_gps payload shape verbatim', () {
      // Mirror exactly what backend's bookings/api/tech_location/views.py
      // emits via publish_stream(payload={...}).
      final json = <String, dynamic>{
        'lat': 31.5204,
        'lng': 74.3587,
        'accuracy_meters': 8.5,
        'heading': 145.0,
        'booking_id': 42,
      };

      final model = TechGpsFrameModel.fromJson(json);

      expect(model.bookingId, 42);
      expect(model.lat, 31.5204);
      expect(model.lng, 74.3587);
      expect(model.accuracyMeters, 8.5);
      expect(model.heading, 145.0);
    });

    test('accepts payload with null optional fields', () {
      final json = <String, dynamic>{
        'lat': 31.5204,
        'lng': 74.3587,
        'accuracy_meters': null,
        'heading': null,
        'booking_id': 42,
      };

      final model = TechGpsFrameModel.fromJson(json);

      expect(model.accuracyMeters, isNull);
      expect(model.heading, isNull);
    });

    test('accepts payload missing optional fields entirely', () {
      // Backend's serializer emits these as null when device omits, but
      // we should not crash if a future version drops them entirely.
      final json = <String, dynamic>{
        'lat': 31.5204,
        'lng': 74.3587,
        'booking_id': 42,
      };

      final model = TechGpsFrameModel.fromJson(json);

      expect(model.accuracyMeters, isNull);
      expect(model.heading, isNull);
    });
  });
}
