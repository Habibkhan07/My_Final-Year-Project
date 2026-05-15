import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/work_location/data/models/work_location_model.dart';

void main() {
  group('WorkLocationModel.fromJson', () {
    test('parses the is_set=true payload', () {
      final model = WorkLocationModel.fromJson({
        'is_set': true,
        'latitude': 31.5204,
        'longitude': 74.3587,
        'max_travel_radius_km': 8,
        'work_address_label': 'Gulberg, Lahore',
      });

      expect(model.isSet, true);
      expect(model.latitude, 31.5204);
      expect(model.longitude, 74.3587);
      expect(model.maxTravelRadiusKm, 8);
      expect(model.workAddressLabel, 'Gulberg, Lahore');
    });

    test('parses the is_set=false payload with nulls', () {
      final model = WorkLocationModel.fromJson({
        'is_set': false,
        'latitude': null,
        'longitude': null,
        'max_travel_radius_km': 10,
        'work_address_label': null,
      });

      expect(model.isSet, false);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.maxTravelRadiusKm, 10);
      expect(model.workAddressLabel, isNull);
    });

    test('defaults gracefully on missing keys', () {
      final model = WorkLocationModel.fromJson(const {});

      expect(model.isSet, false);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.maxTravelRadiusKm, 10);
    });

    test('accepts integer-typed lat/lng', () {
      final model = WorkLocationModel.fromJson({
        'is_set': true,
        'latitude': 31,
        'longitude': 74,
        'max_travel_radius_km': 10,
      });

      expect(model.latitude, 31.0);
      expect(model.longitude, 74.0);
    });

    test('toEntity mirrors fields', () {
      final model = WorkLocationModel.fromJson({
        'is_set': true,
        'latitude': 31.5,
        'longitude': 74.3,
        'max_travel_radius_km': 5,
        'work_address_label': 'X',
      });

      final entity = model.toEntity();
      expect(entity.isSet, true);
      expect(entity.latitude, 31.5);
      expect(entity.longitude, 74.3);
      expect(entity.maxTravelRadiusKm, 5);
      expect(entity.workAddressLabel, 'X');
    });
  });
}
