// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async-Notifier hydrating the orchestrator screen from
/// `GET /api/bookings/<id>/`.
///
/// keepAlive: false on purpose — when the screen is popped, the cache
/// goes with it. The next mount re-fetches. This is intentional: the
/// orchestrator screen is the only consumer; keeping the data alive
/// across nav events would mean the realtime events notifier keeps
/// firing for a screen that isn't visible, wasting cycles.
///
/// **Refresh UX.** Both user-initiated retry and event-driven refresh
/// route through `ref.invalidate(bookingDetailProvider(jobId))`. During
/// the rebuild, `AsyncValue.isRefreshing` is true and prior data is
/// preserved on the value side — the screen renders a thin top progress
/// bar via `detailAsync.isLoading && detailAsync.hasValue` instead of
/// flashing to a spinner. This UX choice matters because realtime events
/// trigger refreshes frequently (every status change, every quote, every
/// cash collection) — a strobing spinner would be miserable.

@ProviderFor(BookingDetailNotifier)
final bookingDetailProvider = BookingDetailNotifierFamily._();

/// Async-Notifier hydrating the orchestrator screen from
/// `GET /api/bookings/<id>/`.
///
/// keepAlive: false on purpose — when the screen is popped, the cache
/// goes with it. The next mount re-fetches. This is intentional: the
/// orchestrator screen is the only consumer; keeping the data alive
/// across nav events would mean the realtime events notifier keeps
/// firing for a screen that isn't visible, wasting cycles.
///
/// **Refresh UX.** Both user-initiated retry and event-driven refresh
/// route through `ref.invalidate(bookingDetailProvider(jobId))`. During
/// the rebuild, `AsyncValue.isRefreshing` is true and prior data is
/// preserved on the value side — the screen renders a thin top progress
/// bar via `detailAsync.isLoading && detailAsync.hasValue` instead of
/// flashing to a spinner. This UX choice matters because realtime events
/// trigger refreshes frequently (every status change, every quote, every
/// cash collection) — a strobing spinner would be miserable.
final class BookingDetailNotifierProvider
    extends $AsyncNotifierProvider<BookingDetailNotifier, BookingDetail> {
  /// Async-Notifier hydrating the orchestrator screen from
  /// `GET /api/bookings/<id>/`.
  ///
  /// keepAlive: false on purpose — when the screen is popped, the cache
  /// goes with it. The next mount re-fetches. This is intentional: the
  /// orchestrator screen is the only consumer; keeping the data alive
  /// across nav events would mean the realtime events notifier keeps
  /// firing for a screen that isn't visible, wasting cycles.
  ///
  /// **Refresh UX.** Both user-initiated retry and event-driven refresh
  /// route through `ref.invalidate(bookingDetailProvider(jobId))`. During
  /// the rebuild, `AsyncValue.isRefreshing` is true and prior data is
  /// preserved on the value side — the screen renders a thin top progress
  /// bar via `detailAsync.isLoading && detailAsync.hasValue` instead of
  /// flashing to a spinner. This UX choice matters because realtime events
  /// trigger refreshes frequently (every status change, every quote, every
  /// cash collection) — a strobing spinner would be miserable.
  BookingDetailNotifierProvider._({
    required BookingDetailNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'bookingDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingDetailNotifierHash();

  @override
  String toString() {
    return r'bookingDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BookingDetailNotifier create() => BookingDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is BookingDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingDetailNotifierHash() =>
    r'906bbc4c1c909330ecd57e593250ad93aee35c06';

/// Async-Notifier hydrating the orchestrator screen from
/// `GET /api/bookings/<id>/`.
///
/// keepAlive: false on purpose — when the screen is popped, the cache
/// goes with it. The next mount re-fetches. This is intentional: the
/// orchestrator screen is the only consumer; keeping the data alive
/// across nav events would mean the realtime events notifier keeps
/// firing for a screen that isn't visible, wasting cycles.
///
/// **Refresh UX.** Both user-initiated retry and event-driven refresh
/// route through `ref.invalidate(bookingDetailProvider(jobId))`. During
/// the rebuild, `AsyncValue.isRefreshing` is true and prior data is
/// preserved on the value side — the screen renders a thin top progress
/// bar via `detailAsync.isLoading && detailAsync.hasValue` instead of
/// flashing to a spinner. This UX choice matters because realtime events
/// trigger refreshes frequently (every status change, every quote, every
/// cash collection) — a strobing spinner would be miserable.

final class BookingDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BookingDetailNotifier,
          AsyncValue<BookingDetail>,
          BookingDetail,
          FutureOr<BookingDetail>,
          int
        > {
  BookingDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'bookingDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Async-Notifier hydrating the orchestrator screen from
  /// `GET /api/bookings/<id>/`.
  ///
  /// keepAlive: false on purpose — when the screen is popped, the cache
  /// goes with it. The next mount re-fetches. This is intentional: the
  /// orchestrator screen is the only consumer; keeping the data alive
  /// across nav events would mean the realtime events notifier keeps
  /// firing for a screen that isn't visible, wasting cycles.
  ///
  /// **Refresh UX.** Both user-initiated retry and event-driven refresh
  /// route through `ref.invalidate(bookingDetailProvider(jobId))`. During
  /// the rebuild, `AsyncValue.isRefreshing` is true and prior data is
  /// preserved on the value side — the screen renders a thin top progress
  /// bar via `detailAsync.isLoading && detailAsync.hasValue` instead of
  /// flashing to a spinner. This UX choice matters because realtime events
  /// trigger refreshes frequently (every status change, every quote, every
  /// cash collection) — a strobing spinner would be miserable.

  BookingDetailNotifierProvider call(int jobId) =>
      BookingDetailNotifierProvider._(argument: jobId, from: this);

  @override
  String toString() => r'bookingDetailProvider';
}

/// Async-Notifier hydrating the orchestrator screen from
/// `GET /api/bookings/<id>/`.
///
/// keepAlive: false on purpose — when the screen is popped, the cache
/// goes with it. The next mount re-fetches. This is intentional: the
/// orchestrator screen is the only consumer; keeping the data alive
/// across nav events would mean the realtime events notifier keeps
/// firing for a screen that isn't visible, wasting cycles.
///
/// **Refresh UX.** Both user-initiated retry and event-driven refresh
/// route through `ref.invalidate(bookingDetailProvider(jobId))`. During
/// the rebuild, `AsyncValue.isRefreshing` is true and prior data is
/// preserved on the value side — the screen renders a thin top progress
/// bar via `detailAsync.isLoading && detailAsync.hasValue` instead of
/// flashing to a spinner. This UX choice matters because realtime events
/// trigger refreshes frequently (every status change, every quote, every
/// cash collection) — a strobing spinner would be miserable.

abstract class _$BookingDetailNotifier extends $AsyncNotifier<BookingDetail> {
  late final _$args = ref.$arg as int;
  int get jobId => _$args;

  FutureOr<BookingDetail> build(int jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BookingDetail>, BookingDetail>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BookingDetail>, BookingDetail>,
              AsyncValue<BookingDetail>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
