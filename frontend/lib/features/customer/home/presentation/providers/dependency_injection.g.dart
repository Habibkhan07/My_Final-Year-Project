// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeRemoteDataSource)
final homeRemoteDataSourceProvider = HomeRemoteDataSourceProvider._();

final class HomeRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          HomeRemoteDataSource,
          HomeRemoteDataSource,
          HomeRemoteDataSource
        >
    with $Provider<HomeRemoteDataSource> {
  HomeRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<HomeRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeRemoteDataSource create(Ref ref) {
    return homeRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRemoteDataSource>(value),
    );
  }
}

String _$homeRemoteDataSourceHash() =>
    r'e13ca8691ff0da045b89fce31309a605597ea825';

@ProviderFor(homeLocalDataSource)
final homeLocalDataSourceProvider = HomeLocalDataSourceProvider._();

final class HomeLocalDataSourceProvider
    extends
        $FunctionalProvider<
          HomeLocalDataSource,
          HomeLocalDataSource,
          HomeLocalDataSource
        >
    with $Provider<HomeLocalDataSource> {
  HomeLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<HomeLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeLocalDataSource create(Ref ref) {
    return homeLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeLocalDataSource>(value),
    );
  }
}

String _$homeLocalDataSourceHash() =>
    r'4c26758e7652e575a776ad3211ebb033b2bed0aa';

@ProviderFor(homeRepository)
final homeRepositoryProvider = HomeRepositoryProvider._();

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  HomeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeRepository create(Ref ref) {
    return homeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRepository>(value),
    );
  }
}

String _$homeRepositoryHash() => r'5a0467f0216e5210cd85a62e8e43a1d6ce097aef';

@ProviderFor(getHomeFeedUseCase)
final getHomeFeedUseCaseProvider = GetHomeFeedUseCaseProvider._();

final class GetHomeFeedUseCaseProvider
    extends
        $FunctionalProvider<
          GetHomeFeedUseCase,
          GetHomeFeedUseCase,
          GetHomeFeedUseCase
        >
    with $Provider<GetHomeFeedUseCase> {
  GetHomeFeedUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getHomeFeedUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getHomeFeedUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetHomeFeedUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetHomeFeedUseCase create(Ref ref) {
    return getHomeFeedUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetHomeFeedUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetHomeFeedUseCase>(value),
    );
  }
}

String _$getHomeFeedUseCaseHash() =>
    r'9ba7176f9b53aa888413a8747c7a4e197dd411b3';
