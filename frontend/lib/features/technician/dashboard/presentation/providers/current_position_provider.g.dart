// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_position_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lightweight cached geolocator one-shot for the dashboard's "X km away"
/// subtext.
///
/// Why a custom provider instead of reusing the addresses feature's
/// `LocationDataSource`:
///   - That data source throws on permission denial — appropriate for the
///     address picker (a hard failure: the user can't pick an address without
///     location). Here, denial is soft: the dashboard still works, the km
///     subtext just hides.
///   - We only need the lat/lng. No reverse-geocoding, no street string.
///
/// Cache window is 5 minutes. The dashboard rebuilds infrequently and the
/// technician hasn't moved meaningfully in 5 minutes for "X km away" purposes.
/// `invalidate` lets a future "refresh" gesture force a fresh fix.

@ProviderFor(CurrentPosition)
final currentPositionProvider = CurrentPositionProvider._();

/// Lightweight cached geolocator one-shot for the dashboard's "X km away"
/// subtext.
///
/// Why a custom provider instead of reusing the addresses feature's
/// `LocationDataSource`:
///   - That data source throws on permission denial — appropriate for the
///     address picker (a hard failure: the user can't pick an address without
///     location). Here, denial is soft: the dashboard still works, the km
///     subtext just hides.
///   - We only need the lat/lng. No reverse-geocoding, no street string.
///
/// Cache window is 5 minutes. The dashboard rebuilds infrequently and the
/// technician hasn't moved meaningfully in 5 minutes for "X km away" purposes.
/// `invalidate` lets a future "refresh" gesture force a fresh fix.
final class CurrentPositionProvider
    extends $AsyncNotifierProvider<CurrentPosition, Position?> {
  /// Lightweight cached geolocator one-shot for the dashboard's "X km away"
  /// subtext.
  ///
  /// Why a custom provider instead of reusing the addresses feature's
  /// `LocationDataSource`:
  ///   - That data source throws on permission denial — appropriate for the
  ///     address picker (a hard failure: the user can't pick an address without
  ///     location). Here, denial is soft: the dashboard still works, the km
  ///     subtext just hides.
  ///   - We only need the lat/lng. No reverse-geocoding, no street string.
  ///
  /// Cache window is 5 minutes. The dashboard rebuilds infrequently and the
  /// technician hasn't moved meaningfully in 5 minutes for "X km away" purposes.
  /// `invalidate` lets a future "refresh" gesture force a fresh fix.
  CurrentPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPositionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPositionHash();

  @$internal
  @override
  CurrentPosition create() => CurrentPosition();
}

String _$currentPositionHash() => r'3e85d5d00a74e2b6d5f8ca7ee85dd3829b947152';

/// Lightweight cached geolocator one-shot for the dashboard's "X km away"
/// subtext.
///
/// Why a custom provider instead of reusing the addresses feature's
/// `LocationDataSource`:
///   - That data source throws on permission denial — appropriate for the
///     address picker (a hard failure: the user can't pick an address without
///     location). Here, denial is soft: the dashboard still works, the km
///     subtext just hides.
///   - We only need the lat/lng. No reverse-geocoding, no street string.
///
/// Cache window is 5 minutes. The dashboard rebuilds infrequently and the
/// technician hasn't moved meaningfully in 5 minutes for "X km away" purposes.
/// `invalidate` lets a future "refresh" gesture force a fresh fix.

abstract class _$CurrentPosition extends $AsyncNotifier<Position?> {
  FutureOr<Position?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Position?>, Position?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Position?>, Position?>,
              AsyncValue<Position?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
