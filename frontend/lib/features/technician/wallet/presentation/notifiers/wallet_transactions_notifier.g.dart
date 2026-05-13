// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transactions_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State holder for the WalletScreen's transaction list section.
///
/// keepAlive: false — disposed with the leaf wallet screen. On next
/// open, ``build`` re-fetches page 1; the dashboard pill stays warm
/// independently for balance refreshes.

@ProviderFor(WalletTransactionsNotifier)
final walletTransactionsProvider = WalletTransactionsNotifierProvider._();

/// State holder for the WalletScreen's transaction list section.
///
/// keepAlive: false — disposed with the leaf wallet screen. On next
/// open, ``build`` re-fetches page 1; the dashboard pill stays warm
/// independently for balance refreshes.
final class WalletTransactionsNotifierProvider
    extends
        $AsyncNotifierProvider<
          WalletTransactionsNotifier,
          WalletTransactionsState
        > {
  /// State holder for the WalletScreen's transaction list section.
  ///
  /// keepAlive: false — disposed with the leaf wallet screen. On next
  /// open, ``build`` re-fetches page 1; the dashboard pill stays warm
  /// independently for balance refreshes.
  WalletTransactionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletTransactionsNotifierHash();

  @$internal
  @override
  WalletTransactionsNotifier create() => WalletTransactionsNotifier();
}

String _$walletTransactionsNotifierHash() =>
    r'cad329878096b59d142116a0b07f18e3d4681b04';

/// State holder for the WalletScreen's transaction list section.
///
/// keepAlive: false — disposed with the leaf wallet screen. On next
/// open, ``build`` re-fetches page 1; the dashboard pill stays warm
/// independently for balance refreshes.

abstract class _$WalletTransactionsNotifier
    extends $AsyncNotifier<WalletTransactionsState> {
  FutureOr<WalletTransactionsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<WalletTransactionsState>,
              WalletTransactionsState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<WalletTransactionsState>,
                WalletTransactionsState
              >,
              AsyncValue<WalletTransactionsState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
