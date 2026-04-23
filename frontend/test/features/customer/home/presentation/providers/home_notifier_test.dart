import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/customer/home/domain/entities/home_feed_entity.dart';
import 'package:frontend/features/customer/home/domain/usecases/get_home_feed_usecase.dart';
import 'package:frontend/features/customer/home/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/home/presentation/providers/home_notifier.dart';
import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';

class MockGetHomeFeedUseCase extends Mock implements GetHomeFeedUseCase {}

void main() {
  late MockGetHomeFeedUseCase mockUseCase;
  late ProviderContainer container;

  const tHomeFeed = HomeFeedEntity(
    categories: [],
    promotions: [],
    fixedGigs: [],
    topTechnicians: [],
  );

  const tDefaultAddress = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: '123 Main St',
    latitude: 31.5204,
    longitude: 74.3587,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  setUp(() {
    mockUseCase = MockGetHomeFeedUseCase();
    container = ProviderContainer(
      overrides: [
        getHomeFeedUseCaseProvider.overrideWithValue(mockUseCase),
        addressesProvider.overrideWith((ref) => Future.value([tDefaultAddress])),
      ],
    );
    addTearDown(() => container.dispose());
  });

  group('HomeNotifier', () {
    test('initial build fetches home feed using default address coordinates', () async {
      when(() => mockUseCase.call(lat: 31.5204, lng: 74.3587))
          .thenAnswer((_) async => tHomeFeed);

      final subscription = container.listen(homeProvider, (_, __) {});
      final state = await container.read(homeProvider.future);

      expect(state.homeFeed, tHomeFeed);
      expect(state.lastLat, 31.5204);
      expect(state.lastLng, 74.3587);

      verify(() => mockUseCase.call(lat: 31.5204, lng: 74.3587)).called(1);
      subscription.close();
    });

    test('initial build fetches without coordinates if no default address exists', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          getHomeFeedUseCaseProvider.overrideWithValue(mockUseCase),
          addressesProvider.overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(() => emptyContainer.dispose());

      when(() => mockUseCase.call(lat: null, lng: null))
          .thenAnswer((_) async => tHomeFeed);

      final subscription = emptyContainer.listen(homeProvider, (_, __) {});
      final state = await emptyContainer.read(homeProvider.future);

      expect(state.homeFeed, tHomeFeed);
      expect(state.lastLat, null);
      expect(state.lastLng, null);

      verify(() => mockUseCase.call(lat: null, lng: null)).called(1);
      subscription.close();
    });

    test('fetchHomeFeed explicitly updates state and coordinates', () async {
      when(() => mockUseCase.call(lat: 31.5204, lng: 74.3587))
          .thenAnswer((_) async => tHomeFeed);
      when(() => mockUseCase.call(lat: 10.0, lng: 20.0))
          .thenAnswer((_) async => tHomeFeed);

      final subscription = container.listen(homeProvider, (_, __) {});
      await container.read(homeProvider.future);

      await container.read(homeProvider.notifier).fetchHomeFeed(lat: 10.0, lng: 20.0);

      final state = container.read(homeProvider).value!;
      expect(state.lastLat, 10.0);
      expect(state.lastLng, 20.0);

      verify(() => mockUseCase.call(lat: 10.0, lng: 20.0)).called(1);
      subscription.close();
    });
  });
}
