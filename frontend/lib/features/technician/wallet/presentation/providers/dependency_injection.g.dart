// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wallet-feature HTTP client. Distinct provider so widget tests can
/// override JUST this dependency with a ``MockClient`` without affecting
/// other features.

@ProviderFor(walletHttpClient)
final walletHttpClientProvider = WalletHttpClientProvider._();

/// Wallet-feature HTTP client. Distinct provider so widget tests can
/// override JUST this dependency with a ``MockClient`` without affecting
/// other features.

final class WalletHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// Wallet-feature HTTP client. Distinct provider so widget tests can
  /// override JUST this dependency with a ``MockClient`` without affecting
  /// other features.
  WalletHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return walletHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$walletHttpClientHash() => r'43a26291c22dcf4b9240c92051629f7d3b18f72a';

@ProviderFor(walletRemoteDataSource)
final walletRemoteDataSourceProvider = WalletRemoteDataSourceProvider._();

final class WalletRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IWalletRemoteDataSource,
          IWalletRemoteDataSource,
          IWalletRemoteDataSource
        >
    with $Provider<IWalletRemoteDataSource> {
  WalletRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IWalletRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IWalletRemoteDataSource create(Ref ref) {
    return walletRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IWalletRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IWalletRemoteDataSource>(value),
    );
  }
}

String _$walletRemoteDataSourceHash() =>
    r'6fbada0e4dfe1c33e17df4f8ae44c891d61b6774';

@ProviderFor(walletRepository)
final walletRepositoryProvider = WalletRepositoryProvider._();

final class WalletRepositoryProvider
    extends
        $FunctionalProvider<
          WalletRepository,
          WalletRepository,
          WalletRepository
        >
    with $Provider<WalletRepository> {
  WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalletRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WalletRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletRepository>(value),
    );
  }
}

String _$walletRepositoryHash() => r'f94a0cde2434a48e9796b426e9d14cd3d6e8a3fa';

/// Withdrawal-flow data source. Reuses [walletHttpClientProvider] so
/// widget tests overriding the wallet client get withdrawal stubs for
/// free, and so the two features share a connection pool.

@ProviderFor(withdrawalRemoteDataSource)
final withdrawalRemoteDataSourceProvider =
    WithdrawalRemoteDataSourceProvider._();

/// Withdrawal-flow data source. Reuses [walletHttpClientProvider] so
/// widget tests overriding the wallet client get withdrawal stubs for
/// free, and so the two features share a connection pool.

final class WithdrawalRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IWithdrawalRemoteDataSource,
          IWithdrawalRemoteDataSource,
          IWithdrawalRemoteDataSource
        >
    with $Provider<IWithdrawalRemoteDataSource> {
  /// Withdrawal-flow data source. Reuses [walletHttpClientProvider] so
  /// widget tests overriding the wallet client get withdrawal stubs for
  /// free, and so the two features share a connection pool.
  WithdrawalRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawalRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawalRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IWithdrawalRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IWithdrawalRemoteDataSource create(Ref ref) {
    return withdrawalRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IWithdrawalRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IWithdrawalRemoteDataSource>(value),
    );
  }
}

String _$withdrawalRemoteDataSourceHash() =>
    r'7e5161818f22af686236c33567da7039811c3804';

/// Withdrawal repository — step 2 of the 4-step error pipeline. Maps
/// HttpFailure / SocketException / FormatException to the sealed
/// [WithdrawalFailure] family.

@ProviderFor(withdrawalRepository)
final withdrawalRepositoryProvider = WithdrawalRepositoryProvider._();

/// Withdrawal repository — step 2 of the 4-step error pipeline. Maps
/// HttpFailure / SocketException / FormatException to the sealed
/// [WithdrawalFailure] family.

final class WithdrawalRepositoryProvider
    extends
        $FunctionalProvider<
          WithdrawalRepository,
          WithdrawalRepository,
          WithdrawalRepository
        >
    with $Provider<WithdrawalRepository> {
  /// Withdrawal repository — step 2 of the 4-step error pipeline. Maps
  /// HttpFailure / SocketException / FormatException to the sealed
  /// [WithdrawalFailure] family.
  WithdrawalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawalRepositoryHash();

  @$internal
  @override
  $ProviderElement<WithdrawalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WithdrawalRepository create(Ref ref) {
    return withdrawalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawalRepository>(value),
    );
  }
}

String _$withdrawalRepositoryHash() =>
    r'c9da36d5152d2239e60cf2f5242fb8712c6830d4';
