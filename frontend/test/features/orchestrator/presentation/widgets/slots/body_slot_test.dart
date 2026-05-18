// Tests for `BodySlot` — the single switch on `BookingStatus` in the
// orchestrator feature.
//
// Adding a new BookingStatus enum value will fail compilation in the
// switch (Dart 3 exhaustiveness). This test pins the *runtime mapping*:
// each existing status renders its dedicated stub widget. A regression
// that swapped a case (e.g. arrived → quoted by typo) would compile
// cleanly but fail this test.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/i_app_map.dart';
import 'package:frontend/core/widgets/map/map_provider.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/animated_status_icon.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/sheets/booking_summary_details_sheet.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/sheets/receipt_sheet.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/slots/body_slot.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/slots/booking_summary_card.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart';
import 'package:latlong2/latlong.dart';

import '../../../_helpers/booking_detail_fixture.dart';

class _NoopAppMap extends StatelessWidget implements IAppMap {
  @override
  final LatLng initialCenter;
  @override
  final double initialZoom;
  @override
  final List<MapMarker> markers;
  @override
  final List<MapPolyline> polylines;
  @override
  final List<MapCircle> circles;
  @override
  final LatLng? cameraTarget;
  @override
  final double? cameraZoom;
  @override
  final List<LatLng>? cameraBounds;
  @override
  final VoidCallback? onUserGesture;

  const _NoopAppMap({
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.cameraTarget,
    this.cameraZoom,
    this.cameraBounds,
    this.onUserGesture,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

AppMapBuilder _noopMapBuilder() {
  return ({
    required initialCenter,
    initialZoom = 15.0,
    markers = const [],
    polylines = const [],
    circles = const [],
    cameraTarget,
    cameraZoom,
    cameraBounds,
    onUserGesture,
  }) => _NoopAppMap(
    initialCenter: initialCenter,
    initialZoom: initialZoom,
    markers: markers,
    polylines: polylines,
    circles: circles,
    cameraTarget: cameraTarget,
    cameraZoom: cameraZoom,
    cameraBounds: cameraBounds,
    onUserGesture: onUserGesture,
  );
}

BookingDetail _bookingFor(BookingStatus s) {
  // Map domain status back to wire string. Keep this table in sync with
  // BookingStatus.fromWire.
  final wire = switch (s) {
    BookingStatus.awaiting => 'AWAITING',
    BookingStatus.confirmed => 'CONFIRMED',
    BookingStatus.enRoute => 'EN_ROUTE',
    BookingStatus.arrived => 'ARRIVED',
    BookingStatus.inspecting => 'INSPECTING',
    BookingStatus.quoted => 'QUOTED',
    BookingStatus.inProgress => 'IN_PROGRESS',
    BookingStatus.completed => 'COMPLETED',
    BookingStatus.completedInspectionOnly => 'COMPLETED_INSPECTION_ONLY',
    BookingStatus.cancelled => 'CANCELLED',
    BookingStatus.techDeclined => 'TECH_DECLINED',
    BookingStatus.techNoResponse => 'TECH_NO_RESPONSE',
    BookingStatus.noShow => 'NO_SHOW',
    BookingStatus.disputed => 'DISPUTED',
    BookingStatus.pending => 'PENDING',
    BookingStatus.unknown => 'UNKNOWN_STATUS_THAT_DOES_NOT_EXIST',
  };
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(bookingDetailJson(status: wire)),
    currentUserId: 7,
  );
}

/// Build a booking with a phase_timestamp override. The base fixture
/// hardcodes most timestamps to null; this helper rebuilds the JSON
/// with a chosen phase set to a specific ISO-8601 string so the
/// WAITING archetype's elapsed counter has something to render against.
BookingDetail _bookingWithPhaseTimestamp({
  required BookingStatus status,
  required String phaseKey,
  required DateTime when,
}) {
  final wire = switch (status) {
    BookingStatus.inspecting => 'INSPECTING',
    BookingStatus.inProgress => 'IN_PROGRESS',
    _ => 'INSPECTING', // Tests only call with INSPECTING / IN_PROGRESS.
  };
  final json = bookingDetailJson(status: wire);
  json['phase_timestamps'] = <String, dynamic>{
    ...?(json['phase_timestamps'] as Map<String, dynamic>?),
    phaseKey: when.toIso8601String(),
  };
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(json),
    currentUserId: 7,
  );
}

/// Build a COMPLETED booking. When `withQuote` is true an active_quote
/// is included on the wire so the inline QuoteSummaryCard + "View
/// receipt" CTA render (Chunk I-lite); when false the body falls back
/// to the celebratory hero only (inspection-only / edge case).
BookingDetail _completedBooking({required bool withQuote}) {
  final json = bookingDetailJson(
    status: 'COMPLETED',
    activeQuote: withQuote
        ? <String, dynamic>{
            'id': 77,
            'booking_id': 42,
            'revision_number': 1,
            'status': 'APPROVED',
            'total_amount': '2500.00',
            'is_upsell': false,
            'submitted_at': '2026-05-18T18:00:00Z',
            'line_items': [
              {
                'id': 1,
                'sub_service_id': 11,
                'sub_service_name': 'Freon Gas Top-up',
                'quantity': 1,
                'priced_at': '2500.00',
                'line_total': '2500.00',
              },
            ],
          }
        : null,
  );
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(json),
    currentUserId: 7,
  );
}

/// Build a QUOTED booking with a real active_quote. `revisionNumber`
/// drives whether the QuoteSummaryCard surfaces the "Revision N"
/// subtitle (it hides on N == 1; see F.3).
BookingDetail _quotedBookingWithQuote({required int revisionNumber}) {
  final quote = <String, dynamic>{
    'id': 99,
    'booking_id': 42,
    'revision_number': revisionNumber,
    'status': 'SUBMITTED',
    'total_amount': '2500.00',
    'is_upsell': false,
    'submitted_at': '2026-05-17T20:00:00Z',
    'line_items': [
      {
        'id': 1,
        'sub_service_id': 11,
        'sub_service_name': 'Freon Gas Top-up',
        'quantity': 1,
        'priced_at': '2500.00',
        'line_total': '2500.00',
      },
    ],
  };
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(
      bookingDetailJson(status: 'QUOTED', activeQuote: quote),
    ),
    currentUserId: 7,
  );
}

void main() {
  // ─── Each known status renders the matching stub ──────────────────────
  final cases = <(BookingStatus, Type)>[
    (BookingStatus.awaiting, AwaitingBodyStub),
    (BookingStatus.confirmed, ConfirmedBodyStub),
    (BookingStatus.enRoute, EnRouteBodyStub),
    (BookingStatus.arrived, ArrivedBodyStub),
    (BookingStatus.inspecting, InspectingBodyStub),
    (BookingStatus.quoted, QuotedBodyStub),
    (BookingStatus.inProgress, InProgressBodyStub),
    (BookingStatus.completed, CompletedBodyStub),
    (BookingStatus.completedInspectionOnly, CompletedInspectionOnlyBodyStub),
    (BookingStatus.cancelled, CancelledBodyStub),
    // Both tech-failure terminal statuses share the same RejectedBodyStub
    // — the BE drives differential copy via the `ui` block.
    (BookingStatus.techDeclined, RejectedBodyStub),
    (BookingStatus.techNoResponse, RejectedBodyStub),
    (BookingStatus.noShow, NoShowBodyStub),
    (BookingStatus.disputed, DisputedBodyStub),
    // pending + unknown both fall through to UnknownBodyStub.
    (BookingStatus.pending, UnknownBodyStub),
    (BookingStatus.unknown, UnknownBodyStub),
  ];

  for (final (status, expectedType) in cases) {
    testWidgets('${status.name} renders ${expectedType.toString()}', (
      tester,
    ) async {
      // EnRoute / Arrived stubs read providers (LiveTrackingMap and the
      // technician location stream). Wrap in a ProviderScope and stub
      // out the map builder to keep this test scoped to the type-match
      // assertion.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(body: BodySlot(booking: _bookingFor(status))),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate((w) => w.runtimeType == expectedType),
        findsOneWidget,
        reason: '${status.name} should render $expectedType',
      );
    });
  }

  // ─── Customer ARRIVED layout contract (Chunk E) ───────────────────────
  //
  // The customer-side ARRIVED body is the map, full stop. No
  // BookingSummaryCard, no "Meeting point" address recap. This guards
  // against regressions where someone adds tech-info or address-recap
  // surfaces back into the ARRIVED scroll (the design rationale is in
  // `_CustomerArrivedBody`'s docstring: tech identity belongs on
  // CONFIRMED/EN_ROUTE, the address belongs to the pin, and ARRIVED
  // is owned by the pinned countdown).
  group('customer ARRIVED layout', () {
    Future<void> pumpArrived(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BodySlot(booking: _bookingFor(BookingStatus.arrived)),
            ),
          ),
        ),
      );
    }

    testWidgets('does NOT render BookingSummaryCard', (tester) async {
      await pumpArrived(tester);
      expect(find.byType(BookingSummaryCard), findsNothing);
    });

    testWidgets('does NOT render the "Meeting point" address recap', (
      tester,
    ) async {
      await pumpArrived(tester);
      expect(find.text('Meeting point'), findsNothing);
    });
  });

  // ─── Customer QUOTED layout contract (Chunk F) ────────────────────────
  //
  // Body is the quote card. No decorative receipt-icon hero. No
  // "Review the quote and approve, decline, or ask for a revision."
  // sentence (the action buttons do that work). These guards pin
  // the redesign so a future revert reintroducing _AnimatedBody on
  // QUOTED fails compilation-adjacent tests.
  group('customer QUOTED layout', () {
    Future<void> pumpQuoted(
      WidgetTester tester, {
      required int revisionNumber,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BodySlot(
                booking: _quotedBookingWithQuote(
                  revisionNumber: revisionNumber,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders QuoteSummaryCard (the actual receipt)', (
      tester,
    ) async {
      await pumpQuoted(tester, revisionNumber: 1);
      expect(find.byType(QuoteSummaryCard), findsOneWidget);
    });

    testWidgets('does NOT render the decorative AnimatedStatusIcon hero', (
      tester,
    ) async {
      await pumpQuoted(tester, revisionNumber: 1);
      expect(find.byType(AnimatedStatusIcon), findsNothing);
    });

    testWidgets('does NOT render the instructional bodyText sentence', (
      tester,
    ) async {
      await pumpQuoted(tester, revisionNumber: 1);
      // The bodyText fixture default is "On the way at 10:00." (from
      // _bookingFor) — but the QUOTED-with-quote variant uses whatever
      // wire string was set, which is empty in our fixture. Either way
      // we assert the old hero-companion phrase is absent.
      expect(
        find.text(
          'Review the quote and approve, decline, or ask for a revision.',
        ),
        findsNothing,
      );
    });
  });

  // ─── QuoteSummaryCard revision-label visibility (Chunk F.3) ───────────
  group('QuoteSummaryCard revision label', () {
    Future<void> pumpQuoted(
      WidgetTester tester, {
      required int revisionNumber,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BodySlot(
                booking: _quotedBookingWithQuote(
                  revisionNumber: revisionNumber,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('revision 1 → label hidden ("Revision 1" not rendered)', (
      tester,
    ) async {
      await pumpQuoted(tester, revisionNumber: 1);
      expect(find.text('Revision 1'), findsNothing);
    });

    testWidgets('revision 2 → label visible', (tester) async {
      await pumpQuoted(tester, revisionNumber: 2);
      expect(find.text('Revision 2'), findsOneWidget);
    });
  });

  // ─── WAITING archetype (Chunk D.1) ────────────────────────────────────
  //
  // AWAITING + INSPECTING + IN_PROGRESS used to render through
  // _AnimatedBody (180-px hero + bodyText). After D.1 they render
  // through _WaitingBody (40-px breathing ring + bodyText + optional
  // elapsed counter). These guards pin the absence of the giant hero
  // — a future revert reintroducing _AnimatedBody on these three
  // statuses fails the AnimatedStatusIcon presence check.
  group('WAITING archetype — no decorative hero', () {
    Future<void> pump(WidgetTester tester, BookingStatus status) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(body: BodySlot(booking: _bookingFor(status))),
          ),
        ),
      );
    }

    for (final status in [
      BookingStatus.awaiting,
      BookingStatus.inspecting,
      BookingStatus.inProgress,
    ]) {
      testWidgets(
        '${status.name} does NOT render AnimatedStatusIcon hero',
        (tester) async {
          await pump(tester, status);
          expect(find.byType(AnimatedStatusIcon), findsNothing);
        },
      );
    }
  });

  // ─── Live elapsed counter (Chunk D.1) ─────────────────────────────────
  group('WAITING archetype — elapsed counter', () {
    Future<void> pump(
      WidgetTester tester,
      BookingDetail booking,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(body: BodySlot(booking: booking)),
          ),
        ),
      );
    }

    testWidgets(
      'INSPECTING with arrivedAt 4 min ago → "Inspecting for 4 min"',
      (tester) async {
        final booking = _bookingWithPhaseTimestamp(
          status: BookingStatus.inspecting,
          phaseKey: 'arrived_at',
          when: DateTime.now().subtract(const Duration(minutes: 4)),
        );
        await pump(tester, booking);
        expect(find.text('Inspecting for 4 min'), findsOneWidget);
      },
    );

    testWidgets(
      'IN_PROGRESS with workStartedAt 24 min ago → "Working for 24 min"',
      (tester) async {
        final booking = _bookingWithPhaseTimestamp(
          status: BookingStatus.inProgress,
          phaseKey: 'work_started_at',
          when: DateTime.now().subtract(const Duration(minutes: 24)),
        );
        await pump(tester, booking);
        expect(find.text('Working for 24 min'), findsOneWidget);
      },
    );

    testWidgets(
      'AWAITING renders no elapsed counter (no anchor on the wire)',
      (tester) async {
        await pump(tester, _bookingFor(BookingStatus.awaiting));
        // No "X min" / "just started" / "for X" label should appear.
        expect(find.textContaining(' min'), findsNothing);
        expect(find.textContaining('just started'), findsNothing);
      },
    );
  });

  // ─── COMPLETED — "View receipt" CTA (Chunk I-lite) ────────────────────
  //
  // When `activeQuote` is present, CompletedBodyStub renders the
  // QuoteSummaryCard inline AND surfaces a "View receipt" button below
  // it. Tap → ReceiptSheet opens. When `activeQuote` is null
  // (inspection-only completion), neither the inline card nor the
  // button render — the body falls back to the celebratory hero only.
  group('COMPLETED receipt CTA', () {
    Future<void> pump(WidgetTester tester, BookingDetail booking) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(body: BodySlot(booking: booking)),
          ),
        ),
      );
    }

    testWidgets(
      'renders "View receipt" button when activeQuote is present',
      (tester) async {
        await pump(tester, _completedBooking(withQuote: true));
        expect(find.text('View receipt'), findsOneWidget);
      },
    );

    testWidgets(
      'omits the button when activeQuote is null',
      (tester) async {
        await pump(tester, _completedBooking(withQuote: false));
        expect(find.text('View receipt'), findsNothing);
        // The inline QuoteSummaryCard is also absent — both belong to
        // the same Column-of-receipt-affordances.
        expect(find.byType(QuoteSummaryCard), findsNothing);
      },
    );

    testWidgets(
      'tap opens the ReceiptSheet',
      (tester) async {
        await pump(tester, _completedBooking(withQuote: true));
        await tester.tap(find.text('View receipt'));
        await tester.pumpAndSettle();
        expect(find.byType(ReceiptSheet), findsOneWidget);
        // Sheet's own copy + a second QuoteSummaryCard mounted inside
        // it (the inline one in the body remains too — the sheet
        // intentionally re-renders for the focused-screenshot use case).
        expect(find.text('Receipt'), findsOneWidget);
        expect(
          find.text('Tap and hold to save a screenshot.'),
          findsOneWidget,
        );
      },
    );
  });

  // ─── BookingSummaryCard slim strip (Chunk L.1) ─────────────────────────
  //
  // Pre-L the card was a ~276-px panel (avatar + service line +
  // schedule line + 3-line address + full-width Call button). L.1
  // collapses it to a ~64-px strip and moves the dropped fields into
  // a tap-to-expand `BookingSummaryDetailsSheet`. These guards pin
  // the slim form so a regression that reintroduces the schedule /
  // address inline fails compilation-adjacent tests.
  group('BookingSummaryCard slim strip', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appMapBuilderProvider.overrideWith((ref) => _noopMapBuilder()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BookingSummaryCard(
                booking: _bookingFor(BookingStatus.confirmed),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders under 90 px tall', (tester) async {
      await pump(tester);
      final size = tester.getSize(find.byType(BookingSummaryCard));
      expect(
        size.height,
        lessThan(90),
        reason: 'Strip should be slim after L.1; got ${size.height} px',
      );
    });

    testWidgets(
      'does NOT render schedule or address fields inline',
      (tester) async {
        await pump(tester);
        // Schedule format would render as e.g. "Today · 10:00 AM – ".
        // Address would render as the full address text.
        expect(find.textContaining('AM – '), findsNothing);
        expect(find.textContaining('PM – '), findsNothing);
        expect(
          find.text('House 1, Street 1, Lahore'),
          findsNothing,
          reason: 'Address moved to the details sheet in L.1',
        );
      },
    );

    testWidgets(
      'does NOT render the full-width labelled Call button',
      (tester) async {
        await pump(tester);
        // Pre-L the strip had "Call {firstName}" as a labelled button.
        // The slim strip has only an icon-only call button.
        expect(find.textContaining('Call '), findsNothing);
      },
    );

    testWidgets(
      'tapping the strip body opens BookingSummaryDetailsSheet',
      (tester) async {
        await pump(tester);
        // Tap on the name text — it sits inside the strip's tap area
        // but outside the icon-only call button.
        await tester.tap(find.text('Ali Raza'));
        await tester.pumpAndSettle();
        expect(find.byType(BookingSummaryDetailsSheet), findsOneWidget);
      },
    );

    testWidgets(
      'details sheet recovers schedule + address',
      (tester) async {
        await pump(tester);
        await tester.tap(find.text('Ali Raza'));
        await tester.pumpAndSettle();
        // Section titles
        expect(find.text('Scheduled'), findsOneWidget);
        expect(find.text('Address'), findsOneWidget);
        // The actual fixture address text surfaces in the body
        expect(find.text('House 1, Street 1, Lahore'), findsOneWidget);
        // Labelled Call button only renders when the technician
        // entity carries a phone — the default fixture leaves
        // `technician.phone_no` empty (the model defaults to ''),
        // so the button is correctly suppressed. The Call-button
        // visibility logic is independently covered by the existing
        // BookingSummaryCard tests in this group.
      },
    );
  });
}
