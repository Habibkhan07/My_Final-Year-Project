import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/customer/addresses/data/models/place_details.dart';
import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/domain/failures/address_failure.dart';
import 'package:frontend/features/customer/addresses/domain/use_cases/get_current_location_use_case.dart';
import 'package:frontend/features/customer/addresses/domain/use_cases/reverse_geocode_use_case.dart';
import 'package:frontend/features/customer/addresses/domain/use_cases/save_address_use_case.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/map_picker_notifier.dart';

class MockGetCurrentLocationUseCase extends Mock
    implements GetCurrentLocationUseCase {}

class MockReverseGeocodeUseCase extends Mock implements ReverseGeocodeUseCase {}

class MockSaveAddressUseCase extends Mock implements SaveAddressUseCase {}

void main() {
  late MockGetCurrentLocationUseCase mockGps;
  late MockReverseGeocodeUseCase mockGeocoder;
  late MockSaveAddressUseCase mockSaver;

  const tLocation = PlaceDetails(
    formattedAddress: 'Gulberg III, Lahore',
    latitude: 31.5,
    longitude: 74.3,
    suburb: 'Gulberg III',
    city: 'Lahore',
    state: 'Punjab',
    country: 'PK',
  );

  const tDhaDetails = PlaceDetails(
    formattedAddress: 'DHA Phase 5, Lahore',
    latitude: 31.4,
    longitude: 74.2,
    suburb: 'DHA Phase 5',
    city: 'Lahore',
    country: 'PK',
  );

  const tEntity = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: 'Gulberg III, Lahore',
    latitude: 31.5,
    longitude: 74.3,
    isDefault: false,
    createdAt: '2024-01-01',
  );

  setUp(() {
    mockGps = MockGetCurrentLocationUseCase();
    mockGeocoder = MockReverseGeocodeUseCase();
    mockSaver = MockSaveAddressUseCase();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        getCurrentLocationUseCaseProvider.overrideWithValue(mockGps),
        reverseGeocodeUseCaseProvider.overrideWithValue(mockGeocoder),
        saveAddressUseCaseProvider.overrideWithValue(mockSaver),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('MapPickerNotifier build()', () {
    test('resolves GPS coordinates and initial street address', () async {
      when(() => mockGps.call()).thenAnswer((_) async => tLocation);
      final container = makeContainer();

      final state = await container.read(mapPickerProvider.future);

      expect(state.latitude, 31.5);
      expect(state.longitude, 74.3);
      expect(state.streetAddress, 'Gulberg III, Lahore');
      expect(state.isGeocoding, false);
      expect(state.selectedLabel, 'Home');
    });

    // NOTE: testing AsyncError from build() in pure-Dart ProviderContainer
    // tests is unreliable because the auto-dispose Timer(Duration.zero)
    // fires before the rejected future can propagate through Riverpod.
    // GPS error states are covered by the widget tests instead.
  });

  group('MapPickerNotifier.onMapPanEnd()', () {
    test('immediately updates coordinates and sets isGeocoding=true', () async {
      when(() => mockGps.call()).thenAnswer((_) async => tLocation);
      when(
        () => mockGeocoder.call(any(), any()),
      ).thenAnswer((_) async => tDhaDetails);

      final container = makeContainer();
      await container.read(mapPickerProvider.future);

      container.read(mapPickerProvider.notifier).onMapPanEnd(31.4, 74.2);

      final state = container.read(mapPickerProvider).requireValue;
      expect(state.latitude, 31.4);
      expect(state.longitude, 74.2);
      expect(state.isGeocoding, true);
    });
  });

  group('MapPickerNotifier.setLabel()', () {
    test('updates selectedLabel synchronously', () async {
      when(() => mockGps.call()).thenAnswer((_) async => tLocation);
      final container = makeContainer();
      await container.read(mapPickerProvider.future);

      container.read(mapPickerProvider.notifier).setLabel('Office');

      expect(
        container.read(mapPickerProvider).requireValue.selectedLabel,
        'Office',
      );
    });

    test('does not affect other state fields when changing label', () async {
      when(() => mockGps.call()).thenAnswer((_) async => tLocation);
      final container = makeContainer();
      await container.read(mapPickerProvider.future);

      container.read(mapPickerProvider.notifier).setLabel('Other');

      final state = container.read(mapPickerProvider).requireValue;
      expect(state.latitude, 31.5);
      expect(state.streetAddress, 'Gulberg III, Lahore');
      expect(state.isGeocoding, false);
    });
  });

  group('MapPickerNotifier.save()', () {
    test('transitions saveState to AsyncData(entity) on success', () async {
      when(() => mockGps.call()).thenAnswer((_) async => tLocation);
      when(
        () => mockSaver.call(
          label: any(named: 'label'),
          streetAddress: any(named: 'streetAddress'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
          neighborhood: any(named: 'neighborhood'),
          suburb: any(named: 'suburb'),
          city: any(named: 'city'),
          state: any(named: 'state'),
          country: any(named: 'country'),
          postalCode: any(named: 'postalCode'),
          localityLabel: any(named: 'localityLabel'),
        ),
      ).thenAnswer((_) async => tEntity);

      final container = makeContainer();
      await container.read(mapPickerProvider.future);

      await container.read(mapPickerProvider.notifier).save(isDefault: false);

      final state = container.read(mapPickerProvider).requireValue;
      expect(state.saveState, isA<AsyncData<CustomerAddressEntity?>>());
      expect(
        (state.saveState as AsyncData<CustomerAddressEntity?>).value,
        tEntity,
      );
    });

    test('passes isDefault=false to the use case', () async {
      when(() => mockGps.call()).thenAnswer((_) async => tLocation);
      when(
        () => mockSaver.call(
          label: any(named: 'label'),
          streetAddress: any(named: 'streetAddress'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
          neighborhood: any(named: 'neighborhood'),
          suburb: any(named: 'suburb'),
          city: any(named: 'city'),
          state: any(named: 'state'),
          country: any(named: 'country'),
          postalCode: any(named: 'postalCode'),
          localityLabel: any(named: 'localityLabel'),
        ),
      ).thenAnswer((_) async => tEntity);

      final container = makeContainer();
      await container.read(mapPickerProvider.future);

      await container.read(mapPickerProvider.notifier).save(isDefault: false);

      verify(
        () => mockSaver.call(
          label: 'Home',
          streetAddress: 'Gulberg III, Lahore',
          latitude: 31.5,
          longitude: 74.3,
          isDefault: false,
          neighborhood: null,
          suburb: 'Gulberg III',
          city: 'Lahore',
          state: 'Punjab',
          country: 'PK',
          postalCode: null,
          localityLabel: 'Gulberg III, Lahore',
        ),
      ).called(1);
    });

    test('transitions saveState to AsyncError on server failure', () async {
      when(() => mockGps.call()).thenAnswer((_) async => tLocation);
      when(
        () => mockSaver.call(
          label: any(named: 'label'),
          streetAddress: any(named: 'streetAddress'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
          neighborhood: any(named: 'neighborhood'),
          suburb: any(named: 'suburb'),
          city: any(named: 'city'),
          state: any(named: 'state'),
          country: any(named: 'country'),
          postalCode: any(named: 'postalCode'),
          localityLabel: any(named: 'localityLabel'),
        ),
      ).thenThrow(const AddressServerFailure('Network unreachable'));

      final container = makeContainer();
      await container.read(mapPickerProvider.future);

      await container.read(mapPickerProvider.notifier).save(isDefault: false);

      final state = container.read(mapPickerProvider).requireValue;
      expect(state.saveState, isA<AsyncError<CustomerAddressEntity?>>());
    });

    test(
      'map state (coords, label) is unchanged after a failed save',
      () async {
        when(() => mockGps.call()).thenAnswer((_) async => tLocation);
        when(
          () => mockSaver.call(
            label: any(named: 'label'),
            streetAddress: any(named: 'streetAddress'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            isDefault: any(named: 'isDefault'),
            neighborhood: any(named: 'neighborhood'),
            suburb: any(named: 'suburb'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            country: any(named: 'country'),
            postalCode: any(named: 'postalCode'),
            localityLabel: any(named: 'localityLabel'),
          ),
        ).thenThrow(const AddressServerFailure('fail'));

        final container = makeContainer();
        await container.read(mapPickerProvider.future);
        container.read(mapPickerProvider.notifier).setLabel('Office');

        await container.read(mapPickerProvider.notifier).save(isDefault: false);

        final state = container.read(mapPickerProvider).requireValue;
        // Map state must survive a save failure
        expect(state.latitude, 31.5);
        expect(state.selectedLabel, 'Office');
      },
    );
  });
}
