// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searchRemoteDataSource)
final searchRemoteDataSourceProvider = SearchRemoteDataSourceProvider._();

final class SearchRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          SearchRemoteDataSource,
          SearchRemoteDataSource,
          SearchRemoteDataSource
        >
    with $Provider<SearchRemoteDataSource> {
  SearchRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<SearchRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchRemoteDataSource create(Ref ref) {
    return searchRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchRemoteDataSource>(value),
    );
  }
}

String _$searchRemoteDataSourceHash() =>
    r'08bbaf960c98245b6e518c4c55ec934cf46a42e3';

@ProviderFor(searchLocalDataSource)
final searchLocalDataSourceProvider = SearchLocalDataSourceProvider._();

final class SearchLocalDataSourceProvider
    extends
        $FunctionalProvider<
          SearchLocalDataSource,
          SearchLocalDataSource,
          SearchLocalDataSource
        >
    with $Provider<SearchLocalDataSource> {
  SearchLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<SearchLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchLocalDataSource create(Ref ref) {
    return searchLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchLocalDataSource>(value),
    );
  }
}

String _$searchLocalDataSourceHash() =>
    r'f454eef08f9d3bf7f7be22ece7167894612228fd';

@ProviderFor(searchRepository)
final searchRepositoryProvider = SearchRepositoryProvider._();

final class SearchRepositoryProvider
    extends
        $FunctionalProvider<
          SearchRepository,
          SearchRepository,
          SearchRepository
        >
    with $Provider<SearchRepository> {
  SearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchRepositoryHash();

  @$internal
  @override
  $ProviderElement<SearchRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchRepository create(Ref ref) {
    return searchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchRepository>(value),
    );
  }
}

String _$searchRepositoryHash() => r'c445145dd5e596848ed63d616abb70d1ce3fcb19';

@ProviderFor(getSearchSuggestionsUseCase)
final getSearchSuggestionsUseCaseProvider =
    GetSearchSuggestionsUseCaseProvider._();

final class GetSearchSuggestionsUseCaseProvider
    extends
        $FunctionalProvider<
          GetSearchSuggestionsUseCase,
          GetSearchSuggestionsUseCase,
          GetSearchSuggestionsUseCase
        >
    with $Provider<GetSearchSuggestionsUseCase> {
  GetSearchSuggestionsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSearchSuggestionsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getSearchSuggestionsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSearchSuggestionsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetSearchSuggestionsUseCase create(Ref ref) {
    return getSearchSuggestionsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSearchSuggestionsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSearchSuggestionsUseCase>(value),
    );
  }
}

String _$getSearchSuggestionsUseCaseHash() =>
    r'82cb4828900d8b0124d690ba50bd92a4c24e24ad';

@ProviderFor(getRecentSearchesUseCase)
final getRecentSearchesUseCaseProvider = GetRecentSearchesUseCaseProvider._();

final class GetRecentSearchesUseCaseProvider
    extends
        $FunctionalProvider<
          GetRecentSearchesUseCase,
          GetRecentSearchesUseCase,
          GetRecentSearchesUseCase
        >
    with $Provider<GetRecentSearchesUseCase> {
  GetRecentSearchesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getRecentSearchesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getRecentSearchesUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetRecentSearchesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetRecentSearchesUseCase create(Ref ref) {
    return getRecentSearchesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetRecentSearchesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetRecentSearchesUseCase>(value),
    );
  }
}

String _$getRecentSearchesUseCaseHash() =>
    r'e9397d3a9c03af73c9a292c7316447ab871d8e34';

@ProviderFor(saveRecentSearchUseCase)
final saveRecentSearchUseCaseProvider = SaveRecentSearchUseCaseProvider._();

final class SaveRecentSearchUseCaseProvider
    extends
        $FunctionalProvider<
          SaveRecentSearchUseCase,
          SaveRecentSearchUseCase,
          SaveRecentSearchUseCase
        >
    with $Provider<SaveRecentSearchUseCase> {
  SaveRecentSearchUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveRecentSearchUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveRecentSearchUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveRecentSearchUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveRecentSearchUseCase create(Ref ref) {
    return saveRecentSearchUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveRecentSearchUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveRecentSearchUseCase>(value),
    );
  }
}

String _$saveRecentSearchUseCaseHash() =>
    r'297bf991dab5ba1c583eb64f31d0d077de5c081f';

@ProviderFor(clearRecentSearchesUseCase)
final clearRecentSearchesUseCaseProvider =
    ClearRecentSearchesUseCaseProvider._();

final class ClearRecentSearchesUseCaseProvider
    extends
        $FunctionalProvider<
          ClearRecentSearchesUseCase,
          ClearRecentSearchesUseCase,
          ClearRecentSearchesUseCase
        >
    with $Provider<ClearRecentSearchesUseCase> {
  ClearRecentSearchesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clearRecentSearchesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clearRecentSearchesUseCaseHash();

  @$internal
  @override
  $ProviderElement<ClearRecentSearchesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClearRecentSearchesUseCase create(Ref ref) {
    return clearRecentSearchesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClearRecentSearchesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClearRecentSearchesUseCase>(value),
    );
  }
}

String _$clearRecentSearchesUseCaseHash() =>
    r'21b62f6d7ad475c8926ea30dde141679e5df1ff3';
