// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocationSearchNotifier)
final locationSearchProvider = LocationSearchNotifierProvider._();

final class LocationSearchNotifierProvider
    extends $NotifierProvider<LocationSearchNotifier, LocationSearchState> {
  LocationSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationSearchNotifierHash();

  @$internal
  @override
  LocationSearchNotifier create() => LocationSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationSearchState>(value),
    );
  }
}

String _$locationSearchNotifierHash() =>
    r'9fb884b9a4433d5d0682fe09eeba1b20ec0baf8f';

abstract class _$LocationSearchNotifier extends $Notifier<LocationSearchState> {
  LocationSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LocationSearchState, LocationSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocationSearchState, LocationSearchState>,
              LocationSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
