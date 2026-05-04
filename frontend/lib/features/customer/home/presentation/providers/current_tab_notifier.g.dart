// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_tab_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Active bottom-nav index for the customer's home shell.
///
/// Scoped to the home-screen mount (NOT `keepAlive`): a logout +
/// re-entry resets to Home (index 0), which matches what users expect
/// when re-launching the app or switching accounts.
///
/// Indices: 0 = Home, 1 = Bookings, 2 = Messages, 3 = Profile.

@ProviderFor(CurrentCustomerTab)
final currentCustomerTabProvider = CurrentCustomerTabProvider._();

/// Active bottom-nav index for the customer's home shell.
///
/// Scoped to the home-screen mount (NOT `keepAlive`): a logout +
/// re-entry resets to Home (index 0), which matches what users expect
/// when re-launching the app or switching accounts.
///
/// Indices: 0 = Home, 1 = Bookings, 2 = Messages, 3 = Profile.
final class CurrentCustomerTabProvider
    extends $NotifierProvider<CurrentCustomerTab, int> {
  /// Active bottom-nav index for the customer's home shell.
  ///
  /// Scoped to the home-screen mount (NOT `keepAlive`): a logout +
  /// re-entry resets to Home (index 0), which matches what users expect
  /// when re-launching the app or switching accounts.
  ///
  /// Indices: 0 = Home, 1 = Bookings, 2 = Messages, 3 = Profile.
  CurrentCustomerTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentCustomerTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentCustomerTabHash();

  @$internal
  @override
  CurrentCustomerTab create() => CurrentCustomerTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$currentCustomerTabHash() =>
    r'20c2a0e2beb40844916a5fa0726d25331cf0d62a';

/// Active bottom-nav index for the customer's home shell.
///
/// Scoped to the home-screen mount (NOT `keepAlive`): a logout +
/// re-entry resets to Home (index 0), which matches what users expect
/// when re-launching the app or switching accounts.
///
/// Indices: 0 = Home, 1 = Bookings, 2 = Messages, 3 = Profile.

abstract class _$CurrentCustomerTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
