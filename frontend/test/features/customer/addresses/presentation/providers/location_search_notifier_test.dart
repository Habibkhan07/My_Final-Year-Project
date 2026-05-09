import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/addresses/domain/entities/place_search_entity.dart';
import 'package:frontend/features/customer/addresses/domain/failures/address_failure.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/location_search_notifier.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/location_search_state.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/customer/addresses/domain/use_cases/search_places_use_case.dart';
import 'package:frontend/features/customer/addresses/domain/use_cases/get_place_details_use_case.dart';

class MockSearchPlacesUseCase extends Mock implements SearchPlacesUseCase {}

class MockGetPlaceDetailsUseCase extends Mock
    implements GetPlaceDetailsUseCase {}

void main() {
  late MockSearchPlacesUseCase mockSearchPlaces;
  late MockGetPlaceDetailsUseCase mockGetPlaceDetails;
  late ProviderContainer container;

  setUp(() {
    mockSearchPlaces = MockSearchPlacesUseCase();
    mockGetPlaceDetails = MockGetPlaceDetailsUseCase();

    container = ProviderContainer(
      overrides: [
        searchPlacesUseCaseProvider.overrideWithValue(mockSearchPlaces),
        getPlaceDetailsUseCaseProvider.overrideWithValue(mockGetPlaceDetails),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LocationSearchNotifier', () {
    test('initial state is correct', () {
      final state = container.read(locationSearchProvider);

      expect(state.query, isEmpty);
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.sessionToken, isNotEmpty);
    });

    test('onQueryChanged clears state when query is empty', () {
      final notifier = container.read(locationSearchProvider.notifier);

      notifier.onQueryChanged('test');
      expect(container.read(locationSearchProvider).query, 'test');
      expect(container.read(locationSearchProvider).isLoading, isTrue);

      notifier.onQueryChanged('');
      expect(container.read(locationSearchProvider).query, isEmpty);
      expect(container.read(locationSearchProvider).isLoading, isFalse);
      expect(container.read(locationSearchProvider).results, isEmpty);
    });
  });
}
