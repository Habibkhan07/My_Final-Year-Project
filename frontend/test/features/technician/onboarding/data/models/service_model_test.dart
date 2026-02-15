import 'package:flutter_test/flutter_test.dart';
// Import your model
import 'package:frontend/features/technician/onboarding/data/models/service_model.dart';

void main() {
  group('SubServiceModel Parsing', () {
    test('SUCCESS: Should parse standard JSON correctly', () {
      final json = {
        "id": 101,
        "name": "Leak Repair",
        "base_price": "1500.50", // String format from Django DecimalField
      };

      final model = SubServiceModel.fromJson(json);

      expect(model.id, 101);
      expect(model.name, "Leak Repair");
      expect(model.basePrice, 1500.50);
    });

    test('EDGE CASE: base_price as an Integer', () {
      // Sometimes APIs omit the decimal if it's .00
      final json = {"id": 102, "name": "Pipe Install", "base_price": 2000};

      final model = SubServiceModel.fromJson(json);

      expect(model.basePrice, 2000.0);
    });

    test('EDGE CASE: base_price as a Double', () {
      final json = {"id": 103, "name": "Valve Fix", "base_price": 750.75};

      final model = SubServiceModel.fromJson(json);

      expect(model.basePrice, 750.75);
    });
  });

  group('ServiceModel Parsing (Hierarchical)', () {
    test('SUCCESS: Should parse nested service tree correctly', () {
      // Matches the output of get_services_with_subservices()
      final json = {
        "id": 1,
        "name": "Plumbing",
        "sub_services": [
          {"id": 101, "name": "Leak Repair", "base_price": "1500.0"},
          {"id": 102, "name": "Drain Unclog", "base_price": "800.0"},
        ],
      };

      final model = ServiceModel.fromJson(json);

      expect(model.name, "Plumbing");
      expect(model.subServices.length, 2);
      expect(model.subServices[0].name, "Leak Repair");
    });

    test('EDGE CASE: sub_services is NULL', () {
      // Happens if prefetch_related results in an empty set
      final json = {"id": 2, "name": "Empty Category", "sub_services": null};

      final model = ServiceModel.fromJson(json);

      expect(model.subServices, isA<List<SubServiceModel>>());
      expect(model.subServices, isEmpty);
    });

    test('EDGE CASE: sub_services key is MISSING', () {
      final json = {"id": 3, "name": "Minimal Category"};

      final model = ServiceModel.fromJson(json);

      expect(model.subServices, isEmpty);
    });
  });

  group('Serialization', () {
    test('toJson() should produce correct keys for local caching', () {
      final model = ServiceModel(
        id: 1,
        name: "Test",
        subServices: [SubServiceModel(id: 99, name: "Sub", basePrice: 10.0)],
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['sub_services'][0]['base_price'], 10.0);
    });
  });
}
