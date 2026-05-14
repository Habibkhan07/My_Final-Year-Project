// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdraw_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the withdrawal-sheet state machine.
///
/// Lifecycle:
///   1. [build]            fetches payout accounts; transitions to
///                          ``editing`` (or ``failed`` on fetch error).
///   2. [setAmount] /
///      [selectTarget]    mutate the form. They implicitly clear any
///                          prior failure so the sheet's "fix and
///                          retry" loop works without a separate
///                          method call.
///   3. [submit]           POSTs the request; transitions to
///                          ``submitting`` then terminal ``success``
///                          or ``failed``.
///   4. [reset]            wipe terminal state so the next "Withdraw"
///                          tap shows the form fresh — used by the
///                          sheet's Done button.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) for the same reason as
/// [TopupNotifier]: more states than just loading/data/error. Errors
/// live in [WithdrawState.failure].
///
/// ``keepAlive: false`` — the sheet is modal; when it dismisses, the
/// notifier disposes and the next tap re-fetches. Stale accounts on
/// re-entry would be a usability bug (tech added a bank account
/// elsewhere and we'd miss it).

@ProviderFor(WithdrawNotifier)
final withdrawProvider = WithdrawNotifierProvider._();

/// Drives the withdrawal-sheet state machine.
///
/// Lifecycle:
///   1. [build]            fetches payout accounts; transitions to
///                          ``editing`` (or ``failed`` on fetch error).
///   2. [setAmount] /
///      [selectTarget]    mutate the form. They implicitly clear any
///                          prior failure so the sheet's "fix and
///                          retry" loop works without a separate
///                          method call.
///   3. [submit]           POSTs the request; transitions to
///                          ``submitting`` then terminal ``success``
///                          or ``failed``.
///   4. [reset]            wipe terminal state so the next "Withdraw"
///                          tap shows the form fresh — used by the
///                          sheet's Done button.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) for the same reason as
/// [TopupNotifier]: more states than just loading/data/error. Errors
/// live in [WithdrawState.failure].
///
/// ``keepAlive: false`` — the sheet is modal; when it dismisses, the
/// notifier disposes and the next tap re-fetches. Stale accounts on
/// re-entry would be a usability bug (tech added a bank account
/// elsewhere and we'd miss it).
final class WithdrawNotifierProvider
    extends $AsyncNotifierProvider<WithdrawNotifier, WithdrawState> {
  /// Drives the withdrawal-sheet state machine.
  ///
  /// Lifecycle:
  ///   1. [build]            fetches payout accounts; transitions to
  ///                          ``editing`` (or ``failed`` on fetch error).
  ///   2. [setAmount] /
  ///      [selectTarget]    mutate the form. They implicitly clear any
  ///                          prior failure so the sheet's "fix and
  ///                          retry" loop works without a separate
  ///                          method call.
  ///   3. [submit]           POSTs the request; transitions to
  ///                          ``submitting`` then terminal ``success``
  ///                          or ``failed``.
  ///   4. [reset]            wipe terminal state so the next "Withdraw"
  ///                          tap shows the form fresh — used by the
  ///                          sheet's Done button.
  ///
  /// Sync ``Notifier`` (not ``AsyncNotifier``) for the same reason as
  /// [TopupNotifier]: more states than just loading/data/error. Errors
  /// live in [WithdrawState.failure].
  ///
  /// ``keepAlive: false`` — the sheet is modal; when it dismisses, the
  /// notifier disposes and the next tap re-fetches. Stale accounts on
  /// re-entry would be a usability bug (tech added a bank account
  /// elsewhere and we'd miss it).
  WithdrawNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawNotifierHash();

  @$internal
  @override
  WithdrawNotifier create() => WithdrawNotifier();
}

String _$withdrawNotifierHash() => r'ae14c751306a25cfd5061634fe4c1737596983c9';

/// Drives the withdrawal-sheet state machine.
///
/// Lifecycle:
///   1. [build]            fetches payout accounts; transitions to
///                          ``editing`` (or ``failed`` on fetch error).
///   2. [setAmount] /
///      [selectTarget]    mutate the form. They implicitly clear any
///                          prior failure so the sheet's "fix and
///                          retry" loop works without a separate
///                          method call.
///   3. [submit]           POSTs the request; transitions to
///                          ``submitting`` then terminal ``success``
///                          or ``failed``.
///   4. [reset]            wipe terminal state so the next "Withdraw"
///                          tap shows the form fresh — used by the
///                          sheet's Done button.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) for the same reason as
/// [TopupNotifier]: more states than just loading/data/error. Errors
/// live in [WithdrawState.failure].
///
/// ``keepAlive: false`` — the sheet is modal; when it dismisses, the
/// notifier disposes and the next tap re-fetches. Stale accounts on
/// re-entry would be a usability bug (tech added a bank account
/// elsewhere and we'd miss it).

abstract class _$WithdrawNotifier extends $AsyncNotifier<WithdrawState> {
  FutureOr<WithdrawState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WithdrawState>, WithdrawState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WithdrawState>, WithdrawState>,
              AsyncValue<WithdrawState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
