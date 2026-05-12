// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State holder for the tech-only Wallet screen.
///
/// Two mutation paths:
///   * [build]          — initial fetch + pull-to-refresh from
///                        ``GET /api/technicians/wallet/``.
///   * [onBalanceEvent] — single-field patch fired by the
///                        ``wallet_balance_updated`` realtime event so the
///                        screen reflects commission deductions / top-ups
///                        without a full reload.
///
/// **keepAlive: false** — the wallet screen is a leaf route, not a tab.
/// When the tech navigates away, the notifier is disposed; on return it
/// re-fetches. The dashboard pill (whose notifier IS keepAlive) is the
/// always-on surface for the same balance, so missing events while the
/// wallet screen is dismissed costs us nothing.

@ProviderFor(WalletNotifier)
final walletProvider = WalletNotifierProvider._();

/// State holder for the tech-only Wallet screen.
///
/// Two mutation paths:
///   * [build]          — initial fetch + pull-to-refresh from
///                        ``GET /api/technicians/wallet/``.
///   * [onBalanceEvent] — single-field patch fired by the
///                        ``wallet_balance_updated`` realtime event so the
///                        screen reflects commission deductions / top-ups
///                        without a full reload.
///
/// **keepAlive: false** — the wallet screen is a leaf route, not a tab.
/// When the tech navigates away, the notifier is disposed; on return it
/// re-fetches. The dashboard pill (whose notifier IS keepAlive) is the
/// always-on surface for the same balance, so missing events while the
/// wallet screen is dismissed costs us nothing.
final class WalletNotifierProvider
    extends $AsyncNotifierProvider<WalletNotifier, WalletState> {
  /// State holder for the tech-only Wallet screen.
  ///
  /// Two mutation paths:
  ///   * [build]          — initial fetch + pull-to-refresh from
  ///                        ``GET /api/technicians/wallet/``.
  ///   * [onBalanceEvent] — single-field patch fired by the
  ///                        ``wallet_balance_updated`` realtime event so the
  ///                        screen reflects commission deductions / top-ups
  ///                        without a full reload.
  ///
  /// **keepAlive: false** — the wallet screen is a leaf route, not a tab.
  /// When the tech navigates away, the notifier is disposed; on return it
  /// re-fetches. The dashboard pill (whose notifier IS keepAlive) is the
  /// always-on surface for the same balance, so missing events while the
  /// wallet screen is dismissed costs us nothing.
  WalletNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletNotifierHash();

  @$internal
  @override
  WalletNotifier create() => WalletNotifier();
}

String _$walletNotifierHash() => r'f01ef8f6b1704460850e540a18d750985da7603d';

/// State holder for the tech-only Wallet screen.
///
/// Two mutation paths:
///   * [build]          — initial fetch + pull-to-refresh from
///                        ``GET /api/technicians/wallet/``.
///   * [onBalanceEvent] — single-field patch fired by the
///                        ``wallet_balance_updated`` realtime event so the
///                        screen reflects commission deductions / top-ups
///                        without a full reload.
///
/// **keepAlive: false** — the wallet screen is a leaf route, not a tab.
/// When the tech navigates away, the notifier is disposed; on return it
/// re-fetches. The dashboard pill (whose notifier IS keepAlive) is the
/// always-on surface for the same balance, so missing events while the
/// wallet screen is dismissed costs us nothing.

abstract class _$WalletNotifier extends $AsyncNotifier<WalletState> {
  FutureOr<WalletState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WalletState>, WalletState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WalletState>, WalletState>,
              AsyncValue<WalletState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
