import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/customer/discovery/domain/entities/discovery_entities.dart';
import 'package:frontend/features/customer/discovery/domain/failures/discovery_failure.dart';
import 'package:frontend/features/customer/discovery/domain/usecases/get_nearby_technicians_usecase.dart';
import 'package:frontend/features/customer/discovery/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/discovery/presentation/providers/discovery_notifier.dart';
import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';

class MockGetNearbyTechniciansUseCase extends Mock
    implements GetNearbyTechniciansUseCase {}

void main() {
  late MockGetNearbyTechniciansUseCase mockUseCase;
  late ProviderContainer container;

  const tTechnician = DiscoveryTechnicianEntity(
    id: 1,
    fullName: 'Ali Raza',
    primaryCategory: 'Plumbing',
    city: 'LHR',
    profilePicture: null,
    ratingAverage: 4.9,
    reviewCount: 120,
    distanceKm: 2.4,
    bayesianScore: 4.8,
    isActive: true,
    uiRatingText: '4.9 (120)',
    primaryPrice: 'Rs. 500',
    priceContext: 'per visit',
    promoTag: null,
    uiSubtitleText: null,
  );

  const tDiscoveryResult = DiscoveryResultEntity(
    count: 1,
    next: 'http://api.com/?page=2',
    previous: null,
    uiPromoBannerText: null,
    results: [tTechnician],
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
    mockUseCase = MockGetNearbyTechniciansUseCase();
    container = ProviderContainer(
      overrides: [
        getNearbyTechniciansUseCaseProvider.overrideWithValue(mockUseCase),
        addressesProvider.overrideWith(
          (ref) => Future.value([tDefaultAddress]),
        ),
      ],
    );
    addTearDown(() => container.dispose());
  });

  group('DiscoveryNotifier Bulletproof Tests', () {
    test(
      'initial build should fetch technicians and set state to AsyncData',
      () async {
        when(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).thenAnswer((_) async => tDiscoveryResult);

        final subscription = container.listen(discoveryProvider(), (_, __) {});
        final state = await container.read(discoveryProvider().future);

        expect(state.discoveryResult, tDiscoveryResult);
        verify(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).called(1);
        subscription.close();
      },
    );

    test('refresh should update the state with fresh data', () async {
      when(
        () => mockUseCase.call(
          page: 1,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).thenAnswer((_) async => tDiscoveryResult);
      final subscription = container.listen(discoveryProvider(), (_, __) {});
      await container.read(discoveryProvider().future);

      await container.read(discoveryProvider().notifier).refresh();

      final state = container.read(discoveryProvider());
      expect(state.value?.discoveryResult, tDiscoveryResult);
      verify(
        () => mockUseCase.call(
          page: 1,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).called(2);
      subscription.close();
    });

    test('loadMore should append new results to the current list', () async {
      const tNextResult = DiscoveryResultEntity(
        count: 2,
        next: null,
        previous: null,
        uiPromoBannerText: null,
        results: [tTechnician],
      );

      when(
        () => mockUseCase.call(
          page: 1,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).thenAnswer((_) async => tDiscoveryResult);
      when(
        () => mockUseCase.call(
          page: 2,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).thenAnswer((_) async => tNextResult);

      final subscription = container.listen(discoveryProvider(), (_, __) {});
      await container.read(discoveryProvider().future);

      await container.read(discoveryProvider().notifier).loadMore();

      final state = container.read(discoveryProvider()).value!;
      expect(state.discoveryResult?.results.length, 2);
      expect(state.isPaginationLoading, false);
      subscription.close();
    });

    test(
      'should propagate DiscoveryFailure into AsyncError state gracefully',
      () async {
        const tFailure = DiscoveryNetworkFailure('No Internet');
        when(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).thenAnswer((_) => Future.error(tFailure));

        final subscription = container.listen(discoveryProvider(), (_, __) {});

        // Just yield to the event loop so the build future can fail
        await Future.delayed(const Duration(milliseconds: 50));

        final state = container.read(discoveryProvider());
        expect(state.hasError, true);
        expect(state.error, tFailure);
        subscription.close();
      },
    );

    test(
      'refresh should recover from an initial build error seamlessly',
      () async {
        const tFailure = DiscoveryNetworkFailure('No Internet');
        when(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).thenAnswer((_) => Future.error(tFailure));

        final subscription = container.listen(discoveryProvider(), (_, __) {});
        await Future.delayed(const Duration(milliseconds: 50));

        expect(container.read(discoveryProvider()).hasError, true);

        // Now mock a successful refresh
        when(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).thenAnswer((_) async => tDiscoveryResult);

        await container.read(discoveryProvider().notifier).refresh();

        final state = container.read(discoveryProvider());
        expect(state, isA<AsyncData>());
        expect(state.value?.discoveryResult, tDiscoveryResult);

        subscription.close();
      },
    );

    test(
      'loadMore should do nothing if state is currently an error (no data to paginate)',
      () async {
        const tFailure = DiscoveryNetworkFailure('No Internet');
        when(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).thenAnswer((_) => Future.error(tFailure));

        final subscription = container.listen(discoveryProvider(), (_, __) {});
        await Future.delayed(const Duration(milliseconds: 50));

        // State is now error. Calling loadMore shouldn't crash or trigger network call.
        await container.read(discoveryProvider().notifier).loadMore();

        verify(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).called(1); // Only the initial build
        verifyNever(
          () => mockUseCase.call(
            page: 2,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        );

        subscription.close();
      },
    );

    test('loadMore should not call usecase if next page is null', () async {
      const tNoNextResult = DiscoveryResultEntity(
        count: 1,
        next: null,
        previous: null,
        uiPromoBannerText: null,
        results: [tTechnician],
      );
      when(
        () => mockUseCase.call(
          page: 1,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).thenAnswer((_) async => tNoNextResult);

      final subscription = container.listen(discoveryProvider(), (_, __) {});
      await container.read(discoveryProvider().future);

      await container.read(discoveryProvider().notifier).loadMore();

      verifyNever(
        () => mockUseCase.call(
          page: 2,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      );
      subscription.close();
    });

    test('loadMore should ignore concurrent calls', () async {
      when(
        () => mockUseCase.call(
          page: 1,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).thenAnswer((_) async => tDiscoveryResult);
      when(
        () => mockUseCase.call(
          page: 2,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return tDiscoveryResult;
      });

      final subscription = container.listen(discoveryProvider(), (_, __) {});
      await container.read(discoveryProvider().future);

      final notifier = container.read(discoveryProvider().notifier);
      final p1 = notifier.loadMore();
      final p2 = notifier.loadMore(); // This second one should abort early

      await p1;
      await p2;

      verify(
        () => mockUseCase.call(
          page: 2,
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          query: any(named: 'query'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).called(1);
      subscription.close();
    });

    test(
      'loadMore failure should emit AsyncError but preserve existing data and reset pagination flag',
      () async {
        when(
          () => mockUseCase.call(
            page: 1,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).thenAnswer((_) async => tDiscoveryResult);
        final subscription = container.listen(discoveryProvider(), (_, __) {});
        await container.read(discoveryProvider().future);

        const tFailure = DiscoveryNetworkFailure('No Internet');
        when(
          () => mockUseCase.call(
            page: 2,
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          ),
        ).thenAnswer((_) => Future.error(tFailure));

        await container.read(discoveryProvider().notifier).loadMore();

        final state = container.read(discoveryProvider());

        expect(state.hasError, true);
        expect(state.error, tFailure);

        // Crucial part: UI doesn't crash because value is preserved
        expect(state.hasValue, true);
        expect(state.value?.discoveryResult, tDiscoveryResult);
        expect(
          state.value?.isPaginationLoading,
          false,
        ); // Restored to false so we can try again

        subscription.close();
      },
    );
  });
}
