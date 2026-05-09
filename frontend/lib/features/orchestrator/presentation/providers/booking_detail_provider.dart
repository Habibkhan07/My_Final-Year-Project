import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/booking_detail.dart';
import 'dependency_injection.dart';

part 'booking_detail_provider.g.dart';

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
@riverpod
class BookingDetailNotifier extends _$BookingDetailNotifier {
  @override
  Future<BookingDetail> build(int jobId) async {
    final useCase = ref.watch(getBookingDetailUseCaseProvider);
    return useCase(jobId);
  }
}
