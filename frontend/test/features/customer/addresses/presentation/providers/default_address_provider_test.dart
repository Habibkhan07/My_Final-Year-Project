import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';

void main() {
  const tDefault = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: 'Gulberg III, Lahore',
    latitude: 31.5,
    longitude: 74.3,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  const tNonDefault = CustomerAddressEntity(
    id: 2,
    label: 'Office',
    streetAddress: 'DHA Phase 5, Lahore',
    latitude: 31.4,
    longitude: 74.2,
    isDefault: false,
    createdAt: '2024-01-02',
  );

  ProviderContainer makeContainer(
    Future<List<CustomerAddressEntity>> Function(Ref) override,
  ) {
    final container = ProviderContainer(
      overrides: [addressesProvider.overrideWith(override)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('defaultAddressProvider derivation', () {
    test('returns the default address when one exists in the list', () async {
      final container = makeContainer((_) async => [tNonDefault, tDefault]);

      final result = await container.read(defaultAddressProvider.future);

      expect(result, equals(tDefault));
    });

    test('returns null when the list is empty', () async {
      final container = makeContainer((_) async => []);

      final result = await container.read(defaultAddressProvider.future);

      expect(result, isNull);
    });

    test('returns null when no address has isDefault == true', () async {
      final container = makeContainer((_) async => [tNonDefault]);

      final result = await container.read(defaultAddressProvider.future);

      expect(result, isNull);
    });
  });
}
