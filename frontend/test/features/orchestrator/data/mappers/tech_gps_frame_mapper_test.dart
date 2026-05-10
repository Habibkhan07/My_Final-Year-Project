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

      expect(entity, isNotNull);
      expect(entity!.bookingId, 42);
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

        expect(entity, isNotNull);
        expect(entity!.accuracyMeters, isNull);
        expect(entity.heading, isNull);
      },
    );

    test('uses DateTime.now when no injection provided', () {
      const model = TechGpsFrameModel(bookingId: 42, lat: 31.5, lng: 74.3);

      final before = DateTime.now();
      final entity = TechGpsFrameMapper.toDomain(model);
      final after = DateTime.now();

      expect(entity, isNotNull);
      expect(
        entity!.frameArrivedAt.isAfter(
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

  // ───────────────────────────────────────────────────────────────────────
  // Audit H5 (S-2) — payload validation
  // ───────────────────────────────────────────────────────────────────────
  // Streams bypass envelope-layer recipient/expiry filters in
  // SystemEventNotifier; the mapper is the only place a malformed
  // tech_gps payload gets stopped. These tests pin the boundary so a
  // future contributor can't silently relax the validator and let an
  // out-of-range frame reach the map widget (where flutter_map can
  // throw and Google clamps differently — either way, broken UX).

  group('TechGpsFrameMapper.toDomain — bounds validation', () {
    DateTime injectedNow() => DateTime.utc(2026, 5, 10);

    test('rejects out-of-range latitude (> 90)', () {
      const model = TechGpsFrameModel(bookingId: 42, lat: 91.0, lng: 0.0);
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('rejects out-of-range latitude (< -90)', () {
      const model = TechGpsFrameModel(bookingId: 42, lat: -90.5, lng: 0.0);
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('rejects out-of-range longitude (> 180)', () {
      const model = TechGpsFrameModel(bookingId: 42, lat: 0.0, lng: 200.0);
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('rejects out-of-range longitude (< -180)', () {
      const model = TechGpsFrameModel(bookingId: 42, lat: 0.0, lng: -181.0);
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('rejects out-of-range heading (> 360)', () {
      // MAP-2 (Batch I): the strict-less validator dropped exactly
      // 360.0 — Geolocator on Android occasionally emits this for
      // due-north — causing a momentary marker freeze. Now the
      // validator accepts the closed [0, 360] interval and toDomain
      // normalises 360.0 → 0.0. The actually-out-of-range case
      // remains rejected.
      const model = TechGpsFrameModel(
        bookingId: 42,
        lat: 31.5,
        lng: 74.3,
        heading: 361.0,
      );
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('normalises heading 360.0 → 0.0 (MAP-2)', () {
      const model = TechGpsFrameModel(
        bookingId: 42,
        lat: 31.5,
        lng: 74.3,
        heading: 360.0,
      );
      final entity = TechGpsFrameMapper.toDomain(model, now: injectedNow);
      expect(entity, isNotNull);
      expect(entity!.heading, 0.0);
    });

    test('rejects infinity heading (MAP-1)', () {
      final model = TechGpsFrameModel(
        bookingId: 42,
        lat: 31.5,
        lng: 74.3,
        heading: double.infinity,
      );
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('rejects infinity latitude (MAP-1)', () {
      final model = TechGpsFrameModel(
        bookingId: 42,
        lat: double.infinity,
        lng: 0.0,
      );
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('rejects negative heading', () {
      const model = TechGpsFrameModel(
        bookingId: 42,
        lat: 31.5,
        lng: 74.3,
        heading: -1.0,
      );
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('rejects NaN latitude', () {
      final model = TechGpsFrameModel(bookingId: 42, lat: double.nan, lng: 0.0);
      expect(TechGpsFrameMapper.toDomain(model, now: injectedNow), isNull);
    });

    test('accepts boundary values (lat=90, lng=180, heading=0, heading≈360)', () {
      const at90 = TechGpsFrameModel(
        bookingId: 42,
        lat: 90.0,
        lng: 180.0,
        heading: 0.0,
      );
      const justUnder360 = TechGpsFrameModel(
        bookingId: 42,
        lat: 31.5,
        lng: 74.3,
        heading: 359.999,
      );
      expect(TechGpsFrameMapper.toDomain(at90, now: injectedNow), isNotNull);
      expect(
        TechGpsFrameMapper.toDomain(justUnder360, now: injectedNow),
        isNotNull,
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

    test('coerces integer wire values to double (MODEL-1)', () {
      // MODEL-1 (Batch I): a hand-crafted payload, debugging tool, or
      // misconfigured client may send `lat: 31` (JSON integer) instead
      // of `lat: 31.0`. Pre-fix the generated `as double` cast threw
      // TypeError, the notifier swallowed it, and the customer
      // silently never saw frames. The custom fromJson converter now
      // accepts any `num` and coerces to double.
      final json = <String, dynamic>{
        'lat': 31, // integer
        'lng': 74, // integer
        'accuracy_meters': 9, // integer
        'heading': 145, // integer
        'booking_id': 42,
      };

      final model = TechGpsFrameModel.fromJson(json);

      expect(model.lat, 31.0);
      expect(model.lng, 74.0);
      expect(model.accuracyMeters, 9.0);
      expect(model.heading, 145.0);
    });
  });
}
