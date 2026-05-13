// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topup_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the JazzCash Hosted Checkout top-up state machine.
///
/// Single source of truth for a multi-screen flow:
///
///   1. ``TopupAmountSheet`` reads ``state.flow == idle`` and calls
///      [start] on submit.
///   2. ``WalletScreen`` watches the state; when it transitions to
///      ``awaitingGateway`` it pushes the ``JazzCashWebviewScreen``
///      with ``state.session!.redirectUrl``.
///   3. The webview's ``NavigationDelegate`` calls [onGatewayReturned]
///      when JazzCash POSTs the browser back to our ``pp_ReturnURL``;
///      this transitions to ``verifying`` and kicks off the poll.
///   4. The poll resolves the terminal status. State flips to
///      ``success`` or ``failed`` accordingly.
///   5. ``WalletScreen`` reacts to the terminal state by showing the
///      ``TopupResultSheet`` and the realtime ``wallet_balance_updated``
///      event has already patched the balance card.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) because the flow has more
/// states than just loading/data/error; the AsyncValue wrapper would
/// just get in the way. Errors are captured inside the state's
/// ``failure`` field instead.

@ProviderFor(TopupNotifier)
final topupProvider = TopupNotifierProvider._();

/// Drives the JazzCash Hosted Checkout top-up state machine.
///
/// Single source of truth for a multi-screen flow:
///
///   1. ``TopupAmountSheet`` reads ``state.flow == idle`` and calls
///      [start] on submit.
///   2. ``WalletScreen`` watches the state; when it transitions to
///      ``awaitingGateway`` it pushes the ``JazzCashWebviewScreen``
///      with ``state.session!.redirectUrl``.
///   3. The webview's ``NavigationDelegate`` calls [onGatewayReturned]
///      when JazzCash POSTs the browser back to our ``pp_ReturnURL``;
///      this transitions to ``verifying`` and kicks off the poll.
///   4. The poll resolves the terminal status. State flips to
///      ``success`` or ``failed`` accordingly.
///   5. ``WalletScreen`` reacts to the terminal state by showing the
///      ``TopupResultSheet`` and the realtime ``wallet_balance_updated``
///      event has already patched the balance card.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) because the flow has more
/// states than just loading/data/error; the AsyncValue wrapper would
/// just get in the way. Errors are captured inside the state's
/// ``failure`` field instead.
final class TopupNotifierProvider
    extends $NotifierProvider<TopupNotifier, TopupState> {
  /// Drives the JazzCash Hosted Checkout top-up state machine.
  ///
  /// Single source of truth for a multi-screen flow:
  ///
  ///   1. ``TopupAmountSheet`` reads ``state.flow == idle`` and calls
  ///      [start] on submit.
  ///   2. ``WalletScreen`` watches the state; when it transitions to
  ///      ``awaitingGateway`` it pushes the ``JazzCashWebviewScreen``
  ///      with ``state.session!.redirectUrl``.
  ///   3. The webview's ``NavigationDelegate`` calls [onGatewayReturned]
  ///      when JazzCash POSTs the browser back to our ``pp_ReturnURL``;
  ///      this transitions to ``verifying`` and kicks off the poll.
  ///   4. The poll resolves the terminal status. State flips to
  ///      ``success`` or ``failed`` accordingly.
  ///   5. ``WalletScreen`` reacts to the terminal state by showing the
  ///      ``TopupResultSheet`` and the realtime ``wallet_balance_updated``
  ///      event has already patched the balance card.
  ///
  /// Sync ``Notifier`` (not ``AsyncNotifier``) because the flow has more
  /// states than just loading/data/error; the AsyncValue wrapper would
  /// just get in the way. Errors are captured inside the state's
  /// ``failure`` field instead.
  TopupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topupNotifierHash();

  @$internal
  @override
  TopupNotifier create() => TopupNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TopupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TopupState>(value),
    );
  }
}

String _$topupNotifierHash() => r'ad080824213ee496b8588af418076f9a72b4e7b5';

/// Drives the JazzCash Hosted Checkout top-up state machine.
///
/// Single source of truth for a multi-screen flow:
///
///   1. ``TopupAmountSheet`` reads ``state.flow == idle`` and calls
///      [start] on submit.
///   2. ``WalletScreen`` watches the state; when it transitions to
///      ``awaitingGateway`` it pushes the ``JazzCashWebviewScreen``
///      with ``state.session!.redirectUrl``.
///   3. The webview's ``NavigationDelegate`` calls [onGatewayReturned]
///      when JazzCash POSTs the browser back to our ``pp_ReturnURL``;
///      this transitions to ``verifying`` and kicks off the poll.
///   4. The poll resolves the terminal status. State flips to
///      ``success`` or ``failed`` accordingly.
///   5. ``WalletScreen`` reacts to the terminal state by showing the
///      ``TopupResultSheet`` and the realtime ``wallet_balance_updated``
///      event has already patched the balance card.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) because the flow has more
/// states than just loading/data/error; the AsyncValue wrapper would
/// just get in the way. Errors are captured inside the state's
/// ``failure`` field instead.

abstract class _$TopupNotifier extends $Notifier<TopupState> {
  TopupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TopupState, TopupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TopupState, TopupState>,
              TopupState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
