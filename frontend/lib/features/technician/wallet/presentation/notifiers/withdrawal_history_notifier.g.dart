// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State holder for [WithdrawalHistoryScreen].
///
/// Mirrors [WalletTransactionsNotifier] in shape — same cursor-paginated
/// load-more semantics, same "preserve existing rows on loadMore
/// failure" UX. The distinct notifier exists because the underlying
/// repository contract differs (withdrawal history is a separate
/// endpoint with its own sealed-failure family).
///
/// ``keepAlive: false`` — the history screen is a leaf route, not a
/// tab. Re-entry re-fetches page 1.

@ProviderFor(WithdrawalHistoryNotifier)
final withdrawalHistoryProvider = WithdrawalHistoryNotifierProvider._();

/// State holder for [WithdrawalHistoryScreen].
///
/// Mirrors [WalletTransactionsNotifier] in shape — same cursor-paginated
/// load-more semantics, same "preserve existing rows on loadMore
/// failure" UX. The distinct notifier exists because the underlying
/// repository contract differs (withdrawal history is a separate
/// endpoint with its own sealed-failure family).
///
/// ``keepAlive: false`` — the history screen is a leaf route, not a
/// tab. Re-entry re-fetches page 1.
final class WithdrawalHistoryNotifierProvider
    extends
        $AsyncNotifierProvider<
          WithdrawalHistoryNotifier,
          WithdrawalHistoryState
        > {
  /// State holder for [WithdrawalHistoryScreen].
  ///
  /// Mirrors [WalletTransactionsNotifier] in shape — same cursor-paginated
  /// load-more semantics, same "preserve existing rows on loadMore
  /// failure" UX. The distinct notifier exists because the underlying
  /// repository contract differs (withdrawal history is a separate
  /// endpoint with its own sealed-failure family).
  ///
  /// ``keepAlive: false`` — the history screen is a leaf route, not a
  /// tab. Re-entry re-fetches page 1.
  WithdrawalHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawalHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawalHistoryNotifierHash();

  @$internal
  @override
  WithdrawalHistoryNotifier create() => WithdrawalHistoryNotifier();
}

String _$withdrawalHistoryNotifierHash() =>
    r'6b8003b7087b8656068793d9b8871b76d866d09e';

/// State holder for [WithdrawalHistoryScreen].
///
/// Mirrors [WalletTransactionsNotifier] in shape — same cursor-paginated
/// load-more semantics, same "preserve existing rows on loadMore
/// failure" UX. The distinct notifier exists because the underlying
/// repository contract differs (withdrawal history is a separate
/// endpoint with its own sealed-failure family).
///
/// ``keepAlive: false`` — the history screen is a leaf route, not a
/// tab. Re-entry re-fetches page 1.

abstract class _$WithdrawalHistoryNotifier
    extends $AsyncNotifier<WithdrawalHistoryState> {
  FutureOr<WithdrawalHistoryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<WithdrawalHistoryState>, WithdrawalHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<WithdrawalHistoryState>,
                WithdrawalHistoryState
              >,
              AsyncValue<WithdrawalHistoryState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
