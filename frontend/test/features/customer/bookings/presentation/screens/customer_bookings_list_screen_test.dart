// CustomerBookingsListScreen — state→render mapping coverage.
//
// We mock the three providers (selected segment, list, counts) by
// subclassing each notifier and overriding `build()` (and `refresh()`
// where the screen calls it). This isolates the screen from data-layer
// behavior — the contract tested here is purely "given AsyncValue X,
// render Y" per session_4 §7's table.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/customer/bookings/domain/entities/bookings_counts.dart';
import 'package:frontend/features/customer/bookings/domain/entities/customer_booking.dart';
import 'package:frontend/features/customer/bookings/domain/failures/customer_bookings_failure.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/customer_bookings_counts_notifier.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/customer_bookings_list_notifier.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/customer_bookings_list_state.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/selected_segment_notifier.dart';
import 'package:frontend/features/customer/bookings/presentation/screens/customer_bookings_list_screen.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/booking_card.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/booking_card_skeleton.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_empty_past.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_empty_upcoming.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_offline_banner.dart';

// ─── mock notifiers ────────────────────────────────────────────────

class _MockSegment extends SelectedSegment {
  _MockSegment(this._initial);
  final BookingSegment _initial;
  @override
  BookingSegment build() => _initial;
}

class _MockList extends CustomerBookingsList {
  _MockList(this.initial);
  final AsyncValue<CustomerBookingsListState> initial;
  int refreshCalls = 0;

  @override
  Future<CustomerBookingsListState> build() {
    return initial.when<Future<CustomerBookingsListState>>(
      data: (s) => Future.value(s),
      error: (e, st) => Future.error(e, st),
      loading: () => Completer<CustomerBookingsListState>().future,
    );
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

class _MockCounts extends CustomerBookingsCounts {
  _MockCounts(this.initial);
  final AsyncValue<BookingsCounts> initial;
  int refreshCalls = 0;

  @override
  Future<BookingsCounts> build() {
    return initial.when<Future<BookingsCounts>>(
      data: (s) => Future.value(s),
      error: (e, st) => Future.error(e, st),
      loading: () => Completer<BookingsCounts>().future,
    );
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

// ─── fixtures ──────────────────────────────────────────────────────

CustomerBooking _booking({
  int id = 1,
  BookingStatus status = BookingStatus.confirmed,
}) {
  return CustomerBooking(
    id: id,
    status: status,
    service: const BookingService(name: 'AC Repair', iconName: 'ac_repair'),
    technician: const BookingTechnician(
      id: 7,
      displayName: 'Ahmed Khan',
      profilePictureUrl: null,
    ),
    addressLabel: 'Home',
    scheduledStart: DateTime(2026, 5, 6, 15, 0),
    scheduledEnd: DateTime(2026, 5, 6, 17, 0),
    createdAt: DateTime(2026, 5, 5, 9, 0),
    price: const BookingPrice(
      amount: 2500,
      context: 'Fixed Price',
      uiLabel: 'Rs. 2,500',
    ),
    ui: const BookingUi(
      badgeText: 'Confirmed',
      badgeTone: BookingUiTone.positive,
      headline: 'Confirmed with Ahmed Khan',
    ),
  );
}

CustomerBookingsListState _state({
  required BookingSegment segment,
  List<CustomerBooking> items = const [],
  bool isStaleCache = false,
  bool isLoadingMore = false,
  bool hasMore = false,
  String? nextCursor,
  DateTime? cachedAt,
}) {
  return CustomerBookingsListState(
    segment: segment,
    items: items,
    nextCursor: nextCursor,
    hasMore: hasMore,
    isLoadingMore: isLoadingMore,
    isStaleCache: isStaleCache,
    cachedAt: cachedAt,
    serverTime: DateTime(2026, 5, 5, 12, 0),
  );
}

final BookingsCounts _counts = BookingsCounts(
  upcoming: 1,
  past: 12,
  serverTime: DateTime(2026, 5, 5, 12, 0),
);

// ─── widget builder ────────────────────────────────────────────────

Widget _build({
  required BookingSegment segment,
  required AsyncValue<CustomerBookingsListState> listState,
  AsyncValue<BookingsCounts>? countsState,
  _MockList? capture,
  _MockCounts? captureCounts,
}) {
  return ProviderScope(
    overrides: [
      selectedSegmentProvider.overrideWith(() => _MockSegment(segment)),
      customerBookingsListProvider.overrideWith(
        () => capture ?? _MockList(listState),
      ),
      customerBookingsCountsProvider.overrideWith(
        () => captureCounts ?? _MockCounts(countsState ?? AsyncData(_counts)),
      ),
    ],
    child: const MaterialApp(home: CustomerBookingsListScreen()),
  );
}

void main() {
  // ───────────────────────── Loading ─────────────────────────

  testWidgets('AsyncLoading (initial, no previous data) → renders skeletons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(segment: BookingSegment.upcoming, listState: const AsyncLoading()),
    );
    await tester.pump();

    expect(find.byType(BookingCardSkeleton), findsWidgets);
  });

  // ───────────────────────── Data ─────────────────────────

  testWidgets('AsyncData empty + upcoming → BookingsEmptyUpcoming', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncData(_state(segment: BookingSegment.upcoming)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BookingsEmptyUpcoming), findsOneWidget);
  });

  testWidgets('AsyncData empty + past → BookingsEmptyPast', (tester) async {
    await tester.pumpWidget(
      _build(
        segment: BookingSegment.past,
        listState: AsyncData(_state(segment: BookingSegment.past)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BookingsEmptyPast), findsOneWidget);
  });

  testWidgets('AsyncData with items → list of BookingCard', (tester) async {
    // ListView.builder lazy-builds only visible items; raise the
    // viewport so all 3 cards are in the visible window.
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncData(
          _state(
            segment: BookingSegment.upcoming,
            items: [_booking(id: 1), _booking(id: 2), _booking(id: 3)],
          ),
        ),
      ),
    );
    // Use fixed pumps instead of pumpAndSettle — SvgPicture.asset
    // loading + AnimatedSwitcher inside cards can keep the frame
    // schedule busy past pumpAndSettle's timeout in widget tests.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BookingCard), findsNWidgets(3));
  });

  testWidgets('AsyncData with isStaleCache=true → offline banner pinned', (
    tester,
  ) async {
    final cachedAt = DateTime(2026, 5, 5, 11, 50);
    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncData(
          _state(
            segment: BookingSegment.upcoming,
            items: [_booking(id: 1)],
            isStaleCache: true,
            cachedAt: cachedAt,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BookingsOfflineBanner), findsOneWidget);
    expect(find.byType(BookingCard), findsOneWidget);
  });

  testWidgets('AsyncData with isLoadingMore=true → footer spinner', (
    tester,
  ) async {
    // Tall viewport so 2 cards + the footer spinner all fit.
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncData(
          _state(
            segment: BookingSegment.upcoming,
            items: [_booking(id: 1), _booking(id: 2)],
            hasMore: true,
            isLoadingMore: true,
            nextCursor: 'cur-1',
          ),
        ),
      ),
    );
    // CircularProgressIndicator animates forever — never pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ───────────────────────── Errors ─────────────────────────

  testWidgets('AsyncError(OfflineNoCache) → offline error state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncError(
          const CustomerBookingsOfflineNoCache(),
          StackTrace.empty,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('AsyncError(ServerFailure) → server error state', (tester) async {
    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncError(
          const CustomerBookingsServerFailure(),
          StackTrace.empty,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your bookings"), findsOneWidget);
    expect(find.textContaining('our end'), findsOneWidget);
  });

  testWidgets('AsyncError(UnknownFailure) → unknown error state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncError(
          const UnknownCustomerBookingsFailure(),
          StackTrace.empty,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your bookings"), findsOneWidget);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  // ───────────────────────── Validation auto-refresh ─────────────────────────

  testWidgets('AsyncError(ValidationFailure) auto-fires refresh() once', (
    tester,
  ) async {
    final capture = _MockList(
      AsyncError(
        const CustomerBookingsValidationFailure(code: 'invalid_cursor'),
        StackTrace.empty,
      ),
    );
    await tester.pumpWidget(
      _build(
        segment: BookingSegment.upcoming,
        listState: AsyncError(
          const CustomerBookingsValidationFailure(code: 'invalid_cursor'),
          StackTrace.empty,
        ),
        capture: capture,
      ),
    );
    await tester.pumpAndSettle();

    // The screen's ref.listen(error: ...) detects the validation
    // failure on first transition and calls refresh() once.
    expect(capture.refreshCalls, 1);
  });

  // ───────────────────────── Pull-to-refresh ─────────────────────────

  testWidgets(
    'pull-to-refresh fires both list.refresh() and counts.refresh()',
    (tester) async {
      final listCapture = _MockList(
        AsyncData(
          _state(segment: BookingSegment.upcoming, items: [_booking(id: 1)]),
        ),
      );
      final countsCapture = _MockCounts(AsyncData(_counts));

      await tester.pumpWidget(
        _build(
          segment: BookingSegment.upcoming,
          listState: AsyncData(
            _state(segment: BookingSegment.upcoming, items: [_booking(id: 1)]),
          ),
          capture: listCapture,
          captureCounts: countsCapture,
        ),
      );
      await tester.pumpAndSettle();

      // Drag the ListView down past the trigger threshold.
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1500);
      await tester.pumpAndSettle();

      expect(listCapture.refreshCalls, greaterThanOrEqualTo(1));
      expect(countsCapture.refreshCalls, greaterThanOrEqualTo(1));
    },
  );
}
