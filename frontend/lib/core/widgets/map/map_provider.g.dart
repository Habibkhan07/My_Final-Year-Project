// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Compile-time map provider — read once at app boot from
/// `--dart-define=MAP_PROVIDER`. Per-screen overriding is intentionally
/// not supported; runtime swap would force every map widget tree to
/// rebuild and re-instantiate native views.

@ProviderFor(mapProviderType)
final mapProviderTypeProvider = MapProviderTypeProvider._();

/// Compile-time map provider — read once at app boot from
/// `--dart-define=MAP_PROVIDER`. Per-screen overriding is intentionally
/// not supported; runtime swap would force every map widget tree to
/// rebuild and re-instantiate native views.

final class MapProviderTypeProvider
    extends
        $FunctionalProvider<MapProviderType, MapProviderType, MapProviderType>
    with $Provider<MapProviderType> {
  /// Compile-time map provider — read once at app boot from
  /// `--dart-define=MAP_PROVIDER`. Per-screen overriding is intentionally
  /// not supported; runtime swap would force every map widget tree to
  /// rebuild and re-instantiate native views.
  MapProviderTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapProviderTypeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapProviderTypeHash();

  @$internal
  @override
  $ProviderElement<MapProviderType> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapProviderType create(Ref ref) {
    return mapProviderType(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapProviderType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapProviderType>(value),
    );
  }
}

String _$mapProviderTypeHash() => r'096f2aa4914e143c561cd8b7733a41118d155291';

/// Builder for the active map widget. Consumers receive this function
/// and construct map widgets through it; they never import OsmAppMap
/// or GoogleAppMap directly.

@ProviderFor(appMapBuilder)
final appMapBuilderProvider = AppMapBuilderProvider._();

/// Builder for the active map widget. Consumers receive this function
/// and construct map widgets through it; they never import OsmAppMap
/// or GoogleAppMap directly.

final class AppMapBuilderProvider
    extends $FunctionalProvider<AppMapBuilder, AppMapBuilder, AppMapBuilder>
    with $Provider<AppMapBuilder> {
  /// Builder for the active map widget. Consumers receive this function
  /// and construct map widgets through it; they never import OsmAppMap
  /// or GoogleAppMap directly.
  AppMapBuilderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appMapBuilderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appMapBuilderHash();

  @$internal
  @override
  $ProviderElement<AppMapBuilder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppMapBuilder create(Ref ref) {
    return appMapBuilder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppMapBuilder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppMapBuilder>(value),
    );
  }
}

String _$appMapBuilderHash() => r'0c9b75a86fc3a413694a30516e8d16a165c04efe';

/// Active directions service for ETA + polyline calls. Reuses the
/// existing realtime singleton `http.Client` so we don't bloat the
/// process with another connection pool just for directions.

@ProviderFor(directionsService)
final directionsServiceProvider = DirectionsServiceProvider._();

/// Active directions service for ETA + polyline calls. Reuses the
/// existing realtime singleton `http.Client` so we don't bloat the
/// process with another connection pool just for directions.

final class DirectionsServiceProvider
    extends
        $FunctionalProvider<
          IDirectionsService,
          IDirectionsService,
          IDirectionsService
        >
    with $Provider<IDirectionsService> {
  /// Active directions service for ETA + polyline calls. Reuses the
  /// existing realtime singleton `http.Client` so we don't bloat the
  /// process with another connection pool just for directions.
  DirectionsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directionsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directionsServiceHash();

  @$internal
  @override
  $ProviderElement<IDirectionsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IDirectionsService create(Ref ref) {
    return directionsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDirectionsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDirectionsService>(value),
    );
  }
}

String _$directionsServiceHash() => r'beed40db1ffff1085a0b2d1aecd03bbd3456ab55';
