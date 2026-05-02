// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(addressHttpClient)
final addressHttpClientProvider = AddressHttpClientProvider._();

final class AddressHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  AddressHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return addressHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$addressHttpClientHash() => r'79c5ffe6407138353b3f72ff5a9705b585604418';

@ProviderFor(addressSecureStorage)
final addressSecureStorageProvider = AddressSecureStorageProvider._();

final class AddressSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  AddressSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return addressSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$addressSecureStorageHash() =>
    r'a1e3cd83c1f36275955ab0a729bf292c1791b6d5';

@ProviderFor(addressRemoteDataSource)
final addressRemoteDataSourceProvider = AddressRemoteDataSourceProvider._();

final class AddressRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AddressRemoteDataSource,
          AddressRemoteDataSource,
          AddressRemoteDataSource
        >
    with $Provider<AddressRemoteDataSource> {
  AddressRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AddressRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AddressRemoteDataSource create(Ref ref) {
    return addressRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddressRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddressRemoteDataSource>(value),
    );
  }
}

String _$addressRemoteDataSourceHash() =>
    r'34bacb6b4c45d6cdf9dc5e82c40db65717fdc29c';

/// Geocoding-provider switch.
///
/// Production: pass `--dart-define=GOOGLE_MAPS_API_KEY=<key>` at build time.
///   → [GoogleMapsGeocodingDataSource] (paid, accurate, in-policy for production)
/// Development: omit the dart-define.
///   → [NominatimGeocodingDataSource] (OSM, dev only — Nominatim's public
///     endpoint forbids production-scale use)
///
/// Switching is intentional and one-line. Repository code is unaware.

@ProviderFor(geocodingDataSource)
final geocodingDataSourceProvider = GeocodingDataSourceProvider._();

/// Geocoding-provider switch.
///
/// Production: pass `--dart-define=GOOGLE_MAPS_API_KEY=<key>` at build time.
///   → [GoogleMapsGeocodingDataSource] (paid, accurate, in-policy for production)
/// Development: omit the dart-define.
///   → [NominatimGeocodingDataSource] (OSM, dev only — Nominatim's public
///     endpoint forbids production-scale use)
///
/// Switching is intentional and one-line. Repository code is unaware.

final class GeocodingDataSourceProvider
    extends
        $FunctionalProvider<
          GeocodingDataSource,
          GeocodingDataSource,
          GeocodingDataSource
        >
    with $Provider<GeocodingDataSource> {
  /// Geocoding-provider switch.
  ///
  /// Production: pass `--dart-define=GOOGLE_MAPS_API_KEY=<key>` at build time.
  ///   → [GoogleMapsGeocodingDataSource] (paid, accurate, in-policy for production)
  /// Development: omit the dart-define.
  ///   → [NominatimGeocodingDataSource] (OSM, dev only — Nominatim's public
  ///     endpoint forbids production-scale use)
  ///
  /// Switching is intentional and one-line. Repository code is unaware.
  GeocodingDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geocodingDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geocodingDataSourceHash();

  @$internal
  @override
  $ProviderElement<GeocodingDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeocodingDataSource create(Ref ref) {
    return geocodingDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeocodingDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeocodingDataSource>(value),
    );
  }
}

String _$geocodingDataSourceHash() =>
    r'5176adf8a05ea046361e21caeca0ff0725ba7c1f';

@ProviderFor(addressLocalDataSource)
final addressLocalDataSourceProvider = AddressLocalDataSourceProvider._();

final class AddressLocalDataSourceProvider
    extends
        $FunctionalProvider<
          AddressLocalDataSource,
          AddressLocalDataSource,
          AddressLocalDataSource
        >
    with $Provider<AddressLocalDataSource> {
  AddressLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<AddressLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AddressLocalDataSource create(Ref ref) {
    return addressLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddressLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddressLocalDataSource>(value),
    );
  }
}

String _$addressLocalDataSourceHash() =>
    r'726f0ced3cc8f573603177daee1918f903b5740d';

@ProviderFor(addressLocationDataSource)
final addressLocationDataSourceProvider = AddressLocationDataSourceProvider._();

final class AddressLocationDataSourceProvider
    extends
        $FunctionalProvider<
          AddressLocationDataSource,
          AddressLocationDataSource,
          AddressLocationDataSource
        >
    with $Provider<AddressLocationDataSource> {
  AddressLocationDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressLocationDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressLocationDataSourceHash();

  @$internal
  @override
  $ProviderElement<AddressLocationDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AddressLocationDataSource create(Ref ref) {
    return addressLocationDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddressLocationDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddressLocationDataSource>(value),
    );
  }
}

String _$addressLocationDataSourceHash() =>
    r'f85ba2f1e4c4fe8424ca55e84f7d002532ddaa53';

@ProviderFor(addressRepository)
final addressRepositoryProvider = AddressRepositoryProvider._();

final class AddressRepositoryProvider
    extends
        $FunctionalProvider<
          IAddressRepository,
          IAddressRepository,
          IAddressRepository
        >
    with $Provider<IAddressRepository> {
  AddressRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressRepositoryHash();

  @$internal
  @override
  $ProviderElement<IAddressRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IAddressRepository create(Ref ref) {
    return addressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAddressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAddressRepository>(value),
    );
  }
}

String _$addressRepositoryHash() => r'd1586911862767b696987d1897bce312fcadbbb5';

@ProviderFor(getAddressesUseCase)
final getAddressesUseCaseProvider = GetAddressesUseCaseProvider._();

final class GetAddressesUseCaseProvider
    extends
        $FunctionalProvider<
          GetAddressesUseCase,
          GetAddressesUseCase,
          GetAddressesUseCase
        >
    with $Provider<GetAddressesUseCase> {
  GetAddressesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getAddressesUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getAddressesUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetAddressesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetAddressesUseCase create(Ref ref) {
    return getAddressesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetAddressesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetAddressesUseCase>(value),
    );
  }
}

String _$getAddressesUseCaseHash() =>
    r'2aa74e947f7ddfeec49181c2be777fce4ab5f641';

@ProviderFor(saveAddressUseCase)
final saveAddressUseCaseProvider = SaveAddressUseCaseProvider._();

final class SaveAddressUseCaseProvider
    extends
        $FunctionalProvider<
          SaveAddressUseCase,
          SaveAddressUseCase,
          SaveAddressUseCase
        >
    with $Provider<SaveAddressUseCase> {
  SaveAddressUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveAddressUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveAddressUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveAddressUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveAddressUseCase create(Ref ref) {
    return saveAddressUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveAddressUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveAddressUseCase>(value),
    );
  }
}

String _$saveAddressUseCaseHash() =>
    r'1f68f60a9d7eb203e1a6e8b5b4e72c41afe53f46';

@ProviderFor(updateAddressUseCase)
final updateAddressUseCaseProvider = UpdateAddressUseCaseProvider._();

final class UpdateAddressUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateAddressUseCase,
          UpdateAddressUseCase,
          UpdateAddressUseCase
        >
    with $Provider<UpdateAddressUseCase> {
  UpdateAddressUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateAddressUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateAddressUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateAddressUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateAddressUseCase create(Ref ref) {
    return updateAddressUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateAddressUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateAddressUseCase>(value),
    );
  }
}

String _$updateAddressUseCaseHash() =>
    r'7eeefcbf510793d3e2027452477c6f06c98fc502';

@ProviderFor(deleteAddressUseCase)
final deleteAddressUseCaseProvider = DeleteAddressUseCaseProvider._();

final class DeleteAddressUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteAddressUseCase,
          DeleteAddressUseCase,
          DeleteAddressUseCase
        >
    with $Provider<DeleteAddressUseCase> {
  DeleteAddressUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAddressUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAddressUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteAddressUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteAddressUseCase create(Ref ref) {
    return deleteAddressUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteAddressUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteAddressUseCase>(value),
    );
  }
}

String _$deleteAddressUseCaseHash() =>
    r'915d79419ff92c4c79d063d979d742db3e287e97';

@ProviderFor(getCurrentLocationUseCase)
final getCurrentLocationUseCaseProvider = GetCurrentLocationUseCaseProvider._();

final class GetCurrentLocationUseCaseProvider
    extends
        $FunctionalProvider<
          GetCurrentLocationUseCase,
          GetCurrentLocationUseCase,
          GetCurrentLocationUseCase
        >
    with $Provider<GetCurrentLocationUseCase> {
  GetCurrentLocationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCurrentLocationUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCurrentLocationUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCurrentLocationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetCurrentLocationUseCase create(Ref ref) {
    return getCurrentLocationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCurrentLocationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCurrentLocationUseCase>(value),
    );
  }
}

String _$getCurrentLocationUseCaseHash() =>
    r'947ad3e6b5673e8a1f826b9bd944458d83996e56';

@ProviderFor(reverseGeocodeUseCase)
final reverseGeocodeUseCaseProvider = ReverseGeocodeUseCaseProvider._();

final class ReverseGeocodeUseCaseProvider
    extends
        $FunctionalProvider<
          ReverseGeocodeUseCase,
          ReverseGeocodeUseCase,
          ReverseGeocodeUseCase
        >
    with $Provider<ReverseGeocodeUseCase> {
  ReverseGeocodeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reverseGeocodeUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reverseGeocodeUseCaseHash();

  @$internal
  @override
  $ProviderElement<ReverseGeocodeUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReverseGeocodeUseCase create(Ref ref) {
    return reverseGeocodeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReverseGeocodeUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReverseGeocodeUseCase>(value),
    );
  }
}

String _$reverseGeocodeUseCaseHash() =>
    r'b3c70a5fe21780694acf3e66ae5fc869cf7fa458';

@ProviderFor(searchPlacesUseCase)
final searchPlacesUseCaseProvider = SearchPlacesUseCaseProvider._();

final class SearchPlacesUseCaseProvider
    extends
        $FunctionalProvider<
          SearchPlacesUseCase,
          SearchPlacesUseCase,
          SearchPlacesUseCase
        >
    with $Provider<SearchPlacesUseCase> {
  SearchPlacesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchPlacesUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchPlacesUseCaseHash();

  @$internal
  @override
  $ProviderElement<SearchPlacesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchPlacesUseCase create(Ref ref) {
    return searchPlacesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchPlacesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchPlacesUseCase>(value),
    );
  }
}

String _$searchPlacesUseCaseHash() =>
    r'e3d1a80d624e953d834116cf91b9753623c1696e';

@ProviderFor(getPlaceDetailsUseCase)
final getPlaceDetailsUseCaseProvider = GetPlaceDetailsUseCaseProvider._();

final class GetPlaceDetailsUseCaseProvider
    extends
        $FunctionalProvider<
          GetPlaceDetailsUseCase,
          GetPlaceDetailsUseCase,
          GetPlaceDetailsUseCase
        >
    with $Provider<GetPlaceDetailsUseCase> {
  GetPlaceDetailsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getPlaceDetailsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getPlaceDetailsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPlaceDetailsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetPlaceDetailsUseCase create(Ref ref) {
    return getPlaceDetailsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetPlaceDetailsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetPlaceDetailsUseCase>(value),
    );
  }
}

String _$getPlaceDetailsUseCaseHash() =>
    r'c7fe56cdb39f97a26f6011c1c6dd4613cdc633de';

@ProviderFor(addresses)
final addressesProvider = AddressesProvider._();

final class AddressesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomerAddressEntity>>,
          List<CustomerAddressEntity>,
          FutureOr<List<CustomerAddressEntity>>
        >
    with
        $FutureModifier<List<CustomerAddressEntity>>,
        $FutureProvider<List<CustomerAddressEntity>> {
  AddressesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressesHash();

  @$internal
  @override
  $FutureProviderElement<List<CustomerAddressEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CustomerAddressEntity>> create(Ref ref) {
    return addresses(ref);
  }
}

String _$addressesHash() => r'74c7e313d449369ecaea04cdba211858d97b949c';

@ProviderFor(defaultAddress)
final defaultAddressProvider = DefaultAddressProvider._();

final class DefaultAddressProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerAddressEntity?>,
          CustomerAddressEntity?,
          FutureOr<CustomerAddressEntity?>
        >
    with
        $FutureModifier<CustomerAddressEntity?>,
        $FutureProvider<CustomerAddressEntity?> {
  DefaultAddressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultAddressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultAddressHash();

  @$internal
  @override
  $FutureProviderElement<CustomerAddressEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CustomerAddressEntity?> create(Ref ref) {
    return defaultAddress(ref);
  }
}

String _$defaultAddressHash() => r'91610feded9c88f29d407d840f25dd6ec3b3bb70';
