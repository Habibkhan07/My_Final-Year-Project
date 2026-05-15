// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The router's source of truth for "what surface should this user see?".
///
/// `keepAlive: true` because the router reads it on every navigation —
/// rebuilding on each read would refetch the endpoint constantly.
/// Invalidate explicitly after onboarding finalize (so the router picks
/// up `Pending`) or on logout.
///
/// Watches [authProvider] so that login/logout transitions trigger a
/// rebuild — without this, a logged-out user who logs back in would see
/// the previous account's cached status.

@ProviderFor(technicianStatus)
final technicianStatusProvider = TechnicianStatusProvider._();

/// The router's source of truth for "what surface should this user see?".
///
/// `keepAlive: true` because the router reads it on every navigation —
/// rebuilding on each read would refetch the endpoint constantly.
/// Invalidate explicitly after onboarding finalize (so the router picks
/// up `Pending`) or on logout.
///
/// Watches [authProvider] so that login/logout transitions trigger a
/// rebuild — without this, a logged-out user who logs back in would see
/// the previous account's cached status.

final class TechnicianStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<TechnicianStatus>,
          TechnicianStatus,
          FutureOr<TechnicianStatus>
        >
    with $FutureModifier<TechnicianStatus>, $FutureProvider<TechnicianStatus> {
  /// The router's source of truth for "what surface should this user see?".
  ///
  /// `keepAlive: true` because the router reads it on every navigation —
  /// rebuilding on each read would refetch the endpoint constantly.
  /// Invalidate explicitly after onboarding finalize (so the router picks
  /// up `Pending`) or on logout.
  ///
  /// Watches [authProvider] so that login/logout transitions trigger a
  /// rebuild — without this, a logged-out user who logs back in would see
  /// the previous account's cached status.
  TechnicianStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianStatusHash();

  @$internal
  @override
  $FutureProviderElement<TechnicianStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TechnicianStatus> create(Ref ref) {
    return technicianStatus(ref);
  }
}

String _$technicianStatusHash() => r'd61ff60cfc89d08f5b5d765017c6c1af44f0c1a8';
