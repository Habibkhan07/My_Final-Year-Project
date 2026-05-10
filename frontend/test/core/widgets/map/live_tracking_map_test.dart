// Widget tests for `LiveTrackingMap`.
//
// Covers the static visual states (waiting / connection-quality bands /
// FAB visibility) AND audit H14's 13 dynamic-state branches T-2a..T-2m:
//   • T-2a  AnimationController dispose path.
//   • T-2b  Hard-jump >200m suppression (skip tween, hard-set position).
//   • T-2c  Tween path between consecutive frames within the threshold.
//   • T-2d  Auto-follow toggle when user manually pans.
//   • T-2e  Recentre FAB tap behaviour.
//   • T-2f  Polyline distance-threshold predicate (>500m moved + cool-
//           down already passed → fires a second fetch).
//   • T-2g  Polyline cooldown predicate (>500m moved but cooldown not
//           yet passed → does NOT fire a second fetch).
//   • T-2h  DirectionsFailure soft-fail (no snackbar, widget survives).
//   • T-2i  ETA 1Hz tickdown (countdown decrements over real-time pump).
//   • T-2j  ETA pill hidden when polyline absent / offline.
//   • T-2k  Phone-call FAB error path (launcher returns false → snackbar).
//   • T-2l  Staleness quality-band transitions across rebuilds.
//   • T-2m  First-fit camera-bounds clears after one post-frame pump.
//
// Architecture note: the audit handoff suggested an `IMapController`
// port modelled on imperative `gmaps.GoogleMapController` semantics.
// In practice `IAppMap` is already declarative — the parent passes
// `cameraTarget`/`cameraBounds`/`onUserGesture` as widget props and the
// concrete adapter animates internally — so the existing
// `appMapBuilderProvider` override IS the seam, no extra port needed.
// The H14 refactor introduces only the `IUrlLauncher` port for the
// phone-call FAB (T-2k); everything else hangs off the recording stub
// + the directions service Riverpod override.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/directions_failures.dart';
import 'package:frontend/core/widgets/map/i_app_map.dart';
import 'package:frontend/core/widgets/map/i_directions_service.dart';
import 'package:frontend/core/widgets/map/live_tracking_map.dart';
import 'package:frontend/core/widgets/map/map_provider.dart';
import 'package:frontend/core/widgets/map/url_launcher_port.dart';
import 'package:latlong2/latlong.dart';

// ──────────────────────────────────────────────────────────────────────
// Recording stub IAppMap
// ──────────────────────────────────────────────────────────────────────

/// Captures the most-recent props the LiveTrackingMap fed to its
/// underlying map widget. Tests assert on these to verify camera /
/// marker / polyline state without rendering a real provider tree.
class MapProbe {
  static List<MapMarker> markers = const [];
  static List<MapPolyline> polylines = const [];
  static LatLng? cameraTarget;
  static double? cameraZoom;
  static List<LatLng>? cameraBounds;
  static VoidCallback? onUserGesture;
  static int buildCount = 0;

  static void reset() {
    markers = const [];
    polylines = const [];
    cameraTarget = null;
    cameraZoom = null;
    cameraBounds = null;
    onUserGesture = null;
    buildCount = 0;
  }

  static MapMarker? markerById(String id) {
    for (final m in markers) {
      if (m.id == id) return m;
    }
    return null;
  }
}

class _StubAppMap extends StatelessWidget implements IAppMap {
  @override
  final LatLng initialCenter;
  @override
  final double initialZoom;
  @override
  final List<MapMarker> markers;
  @override
  final List<MapPolyline> polylines;
  @override
  final LatLng? cameraTarget;
  @override
  final double? cameraZoom;
  @override
  final List<LatLng>? cameraBounds;
  @override
  final VoidCallback? onUserGesture;

  const _StubAppMap({
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.markers = const [],
    this.polylines = const [],
    this.cameraTarget,
    this.cameraZoom,
    this.cameraBounds,
    this.onUserGesture,
  });

  @override
  Widget build(BuildContext context) {
    MapProbe.markers = markers;
    MapProbe.polylines = polylines;
    MapProbe.cameraTarget = cameraTarget;
    MapProbe.cameraZoom = cameraZoom;
    MapProbe.cameraBounds = cameraBounds;
    MapProbe.onUserGesture = onUserGesture;
    MapProbe.buildCount++;
    return Container(color: const Color(0xFFE8EAF0));
  }
}

AppMapBuilder _stubBuilder() {
  return ({
    required initialCenter,
    initialZoom = 15.0,
    markers = const [],
    polylines = const [],
    cameraTarget,
    cameraZoom,
    cameraBounds,
    onUserGesture,
  }) => _StubAppMap(
    initialCenter: initialCenter,
    initialZoom: initialZoom,
    markers: markers,
    polylines: polylines,
    cameraTarget: cameraTarget,
    cameraZoom: cameraZoom,
    cameraBounds: cameraBounds,
    onUserGesture: onUserGesture,
  );
}

// ──────────────────────────────────────────────────────────────────────
// Fake IDirectionsService — configurable per test
// ──────────────────────────────────────────────────────────────────────

class _FakeDirectionsService implements IDirectionsService {
  /// Each call returns the next entry. Once exhausted, repeats the last.
  /// Entries are either a [DirectionsResult] (success) or a
  /// [DirectionsFailure] (throw).
  List<Object> responses = [];

  /// Optional pending completer — when set, calls await this completer
  /// instead of returning immediately. Used to test the "polyline not
  /// yet fetched" rendering state.
  Completer<DirectionsResult>? pendingCompleter;

  final List<({LatLng origin, LatLng destination})> calls = [];

  @override
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    calls.add((origin: origin, destination: destination));
    if (pendingCompleter != null) {
      return pendingCompleter!.future;
    }
    if (responses.isEmpty) {
      throw const UnknownDirectionsFailure('test misconfigured');
    }
    final i = calls.length - 1;
    final entry =
        i < responses.length ? responses[i] : responses[responses.length - 1];
    if (entry is DirectionsResult) return entry;
    if (entry is DirectionsFailure) throw entry;
    throw const UnknownDirectionsFailure('unexpected response type');
  }
}

DirectionsResult _result({
  required int etaSeconds,
  int distanceMeters = 1200,
  Duration ageSinceFetch = Duration.zero,
  List<LatLng>? polyline,
}) {
  return DirectionsResult(
    polyline:
        polyline ?? const [LatLng(31.5204, 74.3587), LatLng(31.5497, 74.3436)],
    etaSeconds: etaSeconds,
    distanceMeters: distanceMeters,
    fetchedAt: DateTime.now().subtract(ageSinceFetch),
  );
}

// ──────────────────────────────────────────────────────────────────────
// Fake IUrlLauncher
// ──────────────────────────────────────────────────────────────────────

class _FakeUrlLauncher implements IUrlLauncher {
  bool nextResult = true;
  final List<Uri> launched = [];

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return nextResult;
  }
}

// ──────────────────────────────────────────────────────────────────────
// Container + harness
// ──────────────────────────────────────────────────────────────────────

ProviderContainer _container({
  IDirectionsService? directions,
  IUrlLauncher? launcher,
}) {
  final c = ProviderContainer(
    overrides: [
      appMapBuilderProvider.overrideWith((ref) => _stubBuilder()),
      if (directions != null)
        directionsServiceProvider.overrideWith((ref) => directions),
      if (launcher != null) urlLauncherProvider.overrideWith((ref) => launcher),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Widget _wrap(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(body: SizedBox(height: 600, width: 400, child: child)),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────

void main() {
  const destination = LatLng(31.5497, 74.3436);
  const techStart = LatLng(31.5204, 74.3587);

  setUp(MapProbe.reset);

  // ────────── Existing static-state coverage (kept) ──────────────────

  testWidgets(
    'shows "Waiting for technician\'s location…" before first frame',
    (tester) async {
      final c = _container();
      await tester.pumpWidget(
        _wrap(
          c,
          const LiveTrackingMap(
            technicianPosition: null,
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      expect(
        find.textContaining("Waiting for technician's location"),
        findsOneWidget,
      );
    },
  );

  testWidgets('hides waiting pill once a tech position is supplied', (
    tester,
  ) async {
    final c = _container(directions: _FakeDirectionsService());
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: techStart,
          lastFrameAt: DateTime.now(),
          destination: destination,
          phase: TrackingPhase.enRoute,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining("Waiting for technician's location"),
      findsNothing,
    );
  });

  testWidgets('shows "Technician\'s phone seems to be offline" banner '
      'when last frame is >60s old', (tester) async {
    final c = _container(directions: _FakeDirectionsService());
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: techStart,
          lastFrameAt: DateTime.now().subtract(const Duration(seconds: 90)),
          destination: destination,
          phase: TrackingPhase.enRoute,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining("Technician's phone seems to be offline"),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows "Connection is weak…" banner when last frame is between 15 '
    'and 60s old',
    (tester) async {
      final c = _container(directions: _FakeDirectionsService());
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now().subtract(const Duration(seconds: 30)),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Connection is weak'), findsOneWidget);
      expect(find.textContaining('offline'), findsNothing);
    },
  );

  testWidgets('shows no banner when frame is fresh (<15s)', (tester) async {
    final c = _container(directions: _FakeDirectionsService());
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: techStart,
          lastFrameAt: DateTime.now(),
          destination: destination,
          phase: TrackingPhase.enRoute,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Connection is weak'), findsNothing);
    expect(find.textContaining('offline'), findsNothing);
  });

  testWidgets('phone-call FAB appears only when callPhoneNumber supplied', (
    tester,
  ) async {
    final c = _container(directions: _FakeDirectionsService());
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: techStart,
          lastFrameAt: DateTime.now(),
          destination: destination,
          phase: TrackingPhase.enRoute,
          callPhoneNumber: null,
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.phone), findsNothing);

    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: techStart,
          lastFrameAt: DateTime.now(),
          destination: destination,
          phase: TrackingPhase.enRoute,
          callPhoneNumber: '+923001234567',
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.phone), findsOneWidget);
  });

  // ────────── T-2a: AnimationController dispose path ──────────────────

  testWidgets('T-2a unmounting disposes AnimationController without error', (
    tester,
  ) async {
    final c = _container(directions: _FakeDirectionsService());
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: techStart,
          lastFrameAt: DateTime.now(),
          destination: destination,
          phase: TrackingPhase.enRoute,
        ),
      ),
    );
    await tester.pump();
    // Replace with a barren widget — flushes dispose() on the
    // LiveTrackingMap state. AnimationController.dispose throws if
    // listeners remain; tickers throw if not cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  // ────────── T-2b: Hard-jump >200m suppression ───────────────────────

  testWidgets(
    'T-2b jump >200m hard-sets the technician marker (no tween in flight)',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 300)];
      final c = _container(directions: fake);

      // First mount: tech at start.
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();

      // Far jump — ~5km eastward (well above the 200m hard-jump
      // threshold). The controller should hard-set rather than tween.
      const techJumped = LatLng(31.5204, 74.4087);
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techJumped,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();

      final marker = MapProbe.markerById('technician')!;
      expect(marker.position.latitude, techJumped.latitude);
      expect(marker.position.longitude, techJumped.longitude);
    },
  );

  // ────────── T-2c: Tween path between frames ─────────────────────────

  testWidgets(
    'T-2c marker tweens linearly between frames within hard-jump threshold',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 300)];
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();

      // ~50m northward — well under the 200m hard-jump bound, so the
      // controller should tween (4800ms duration).
      const techNudged = LatLng(31.5209, 74.3587);
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techNudged,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();

      // Halfway through the tween — marker should sit between start
      // and end on the latitude axis.
      await tester.pump(const Duration(milliseconds: 2400));
      final mid = MapProbe.markerById('technician')!;
      expect(
        mid.position.latitude,
        greaterThan(techStart.latitude),
        reason: 'mid-tween latitude should have moved past the start',
      );
      expect(
        mid.position.latitude,
        lessThan(techNudged.latitude),
        reason: 'mid-tween latitude should not yet have reached the end',
      );

      // Run the tween out — marker should land on the new position.
      await tester.pump(const Duration(milliseconds: 2500));
      final end = MapProbe.markerById('technician')!;
      expect(end.position.latitude, closeTo(techNudged.latitude, 1e-6));
    },
  );

  // ────────── T-2d: Auto-follow toggle on user gesture ────────────────

  testWidgets('T-2d invoking onUserGesture surfaces the recentre FAB', (
    tester,
  ) async {
    final fake = _FakeDirectionsService()
      ..responses = [_result(etaSeconds: 180)];
    final c = _container(directions: fake);
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: techStart,
          lastFrameAt: DateTime.now(),
          destination: destination,
          phase: TrackingPhase.enRoute,
        ),
      ),
    );
    await tester.pump();

    // Auto-follow ON → recentre FAB hidden.
    expect(find.byIcon(Icons.my_location), findsNothing);

    // Simulate a user pan via the captured callback.
    expect(MapProbe.onUserGesture, isNotNull);
    MapProbe.onUserGesture!();
    await tester.pump();

    // Auto-follow OFF → recentre FAB visible.
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  // ────────── T-2e: Recentre FAB tap re-engages follow ────────────────

  testWidgets(
    'T-2e tapping the recentre FAB re-engages auto-follow and pushes '
    'cameraTarget=tech position',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 180)];
      final c = _container(directions: fake);
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();

      // Force auto-follow off via gesture so the FAB shows.
      MapProbe.onUserGesture!();
      await tester.pump();
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      // Tap recentre.
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();

      // Right after tap, before the post-frame clear, cameraTarget
      // should hold the tech position.
      expect(MapProbe.cameraTarget?.latitude, closeTo(techStart.latitude, 1e-9));
      expect(
        MapProbe.cameraTarget?.longitude,
        closeTo(techStart.longitude, 1e-9),
      );

      // After the post-frame clear runs, FAB hides again (auto-follow
      // back on).
      await tester.pump();
      expect(find.byIcon(Icons.my_location), findsNothing);
    },
  );

  // ────────── T-2f: Polyline distance-threshold predicate ─────────────

  testWidgets(
    'T-2f tech moves >500m AFTER cooldown elapsed → directions refetched',
    (tester) async {
      // Seed first response with fetchedAt 31s in the past so that on
      // the second `_maybeFetchDirections` the cooldown predicate
      // evaluates true. Real wallclock would otherwise need a 30s pump.
      final fake = _FakeDirectionsService()
        ..responses = [
          _result(
            etaSeconds: 300,
            ageSinceFetch: const Duration(seconds: 31),
          ),
          _result(etaSeconds: 240),
        ];
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      expect(fake.calls, hasLength(1));

      // Move the tech ~5km east — well past the 500m refresh threshold.
      const techFar = LatLng(31.5204, 74.4087);
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techFar,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();

      // Second fetch fired because movedFar=true && cooldownPassed=true.
      expect(fake.calls, hasLength(2));
    },
  );

  // ────────── T-2g: Polyline cooldown gate ─────────────────────────────

  testWidgets(
    'T-2g tech moves >500m WITHIN cooldown window → no second fetch',
    (tester) async {
      // First response is "just fetched" — cooldown has 30s remaining.
      final fake = _FakeDirectionsService()
        ..responses = [
          _result(etaSeconds: 300),
          _result(etaSeconds: 240),
        ];
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      expect(fake.calls, hasLength(1));

      // Move >500m but the just-fetched directions should keep the
      // cooldown gate closed.
      const techFar = LatLng(31.5204, 74.4087);
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techFar,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();

      expect(fake.calls, hasLength(1));
    },
  );

  // ────────── T-2h: DirectionsFailure soft-fail ────────────────────────

  testWidgets(
    'T-2h DirectionsFailure is swallowed silently — no snackbar, widget '
    'continues to render',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [const DirectionsServerFailure(503)];
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      // Let the directions future reject + the finally block run.
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);

      // ETA pill must NOT render — there's no DirectionsResult.
      expect(find.text('min'), findsNothing);
    },
  );

  // ────────── T-2i: ETA tickdown ──────────────────────────────────────

  testWidgets(
    'T-2i ETA pill counts down by minute as time advances',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 120, distanceMeters: 1500)];
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      // Resolve the directions future.
      await tester.pump(const Duration(milliseconds: 10));

      // 120 seconds → ceil(120/60) = 2 → "2".
      expect(find.text('2'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);

      // Pump 61 seconds — countdown drops to 59s → ceil(59/60) = 1.
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
    },
  );

  // ────────── T-2j: ETA pill hidden states ────────────────────────────

  testWidgets(
    'T-2j ETA pill hides when directions not yet fetched',
    (tester) async {
      // Pending completer keeps the directions future open forever.
      final fake = _FakeDirectionsService()
        ..pendingCompleter = Completer<DirectionsResult>();
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('min'), findsNothing);
    },
  );

  testWidgets(
    'T-2j ETA pill hides when connection is offline (>60s stale)',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 240)];
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now().subtract(const Duration(seconds: 90)),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      // Give the directions future time to resolve.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('min'), findsNothing);
      // Sanity: the offline banner IS visible — we're in offline state,
      // not pre-first-frame.
      expect(
        find.textContaining("Technician's phone seems to be offline"),
        findsOneWidget,
      );
    },
  );

  // ────────── T-2k: Phone-call FAB error path ─────────────────────────

  testWidgets(
    'T-2k phone-call FAB shows snackbar when launcher returns false',
    (tester) async {
      final fakeDirections = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 180)];
      final fakeLauncher = _FakeUrlLauncher()..nextResult = false;
      final c = _container(
        directions: fakeDirections,
        launcher: fakeLauncher,
      );

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
            callPhoneNumber: '+923001234567',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump(); // microtask for launch
      await tester.pump(const Duration(milliseconds: 50));

      expect(fakeLauncher.launched, hasLength(1));
      expect(fakeLauncher.launched.first.scheme, 'tel');
      expect(fakeLauncher.launched.first.path, '+923001234567');
      expect(
        find.textContaining('Could not open dialler for +923001234567'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'T-2k phone-call FAB shows no snackbar when launcher returns true',
    (tester) async {
      final fakeDirections = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 180)];
      final fakeLauncher = _FakeUrlLauncher()..nextResult = true;
      final c = _container(
        directions: fakeDirections,
        launcher: fakeLauncher,
      );

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
            callPhoneNumber: '+923001234567',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fakeLauncher.launched, hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  // ────────── T-2l: Staleness band transitions ────────────────────────

  testWidgets(
    'T-2l staleness band transitions across rebuilds (good → weak → '
    'offline)',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 300)];
      final c = _container(directions: fake);

      // 1: fresh → no banner.
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Connection is weak'), findsNothing);
      expect(find.textContaining('offline'), findsNothing);

      // 2: 30s old → weak.
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now().subtract(const Duration(seconds: 30)),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Connection is weak'), findsOneWidget);
      expect(find.textContaining('offline'), findsNothing);

      // 3: 90s old → offline.
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now().subtract(const Duration(seconds: 90)),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Connection is weak'), findsNothing);
      expect(
        find.textContaining("Technician's phone seems to be offline"),
        findsOneWidget,
      );
    },
  );

  // ────────── T-2m: First-fit camera-bounds clears ────────────────────

  testWidgets(
    'T-2m initial mount sets cameraBounds; post-frame clears it back '
    'to null',
    (tester) async {
      final fake = _FakeDirectionsService()
        ..responses = [_result(etaSeconds: 300)];
      final c = _container(directions: fake);

      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: techStart,
            lastFrameAt: DateTime.now(),
            destination: destination,
            phase: TrackingPhase.enRoute,
          ),
        ),
      );

      // First frame: cameraBounds populated with [tech, destination].
      // We need to capture the props from the FIRST build, before the
      // post-frame callback flips them back to null. The widget builds
      // synchronously during pumpWidget so the probe already has them.
      expect(MapProbe.cameraBounds, isNotNull);
      expect(MapProbe.cameraBounds!.length, 2);

      // Pump the post-frame callback — the controller setStates
      // cameraBounds=null.
      await tester.pump();
      expect(MapProbe.cameraBounds, isNull);
    },
  );

  // ────────── T-2n: shortest-arc heading lerp (audit W-12) ─────────────
  // Pure-math unit tests for the `shortestArcLerpDegrees` helper.
  // Pre-fix the marker hard-set heading on every frame, producing a
  // visible snap mid-tween; post-fix the heading lerps along the
  // shortest arc on the [0, 360) circle.

  group('shortestArcLerpDegrees (audit W-12)', () {
    test('forward small delta: 10 -> 20 at t=0.5 returns 15', () {
      expect(shortestArcLerpDegrees(10, 20, 0.5), closeTo(15, 1e-9));
    });

    test('wrap forward: 359 -> 1 at t=0.5 returns 0 (NOT 180)', () {
      // The naive (1-359)*0.5 + 359 = 180 path is wrong — that is the
      // long way around. Shortest arc is +2 deg → midpoint = 0.
      expect(shortestArcLerpDegrees(359, 1, 0.5), closeTo(0, 1e-9));
    });

    test('wrap backward: 1 -> 359 at t=0.5 returns 0', () {
      // Mirror of the forward case — shortest arc is -2 deg →
      // midpoint = 0.
      expect(shortestArcLerpDegrees(1, 359, 0.5), closeTo(0, 1e-9));
    });

    test('antipodal 0 -> 180 at t=0.5 returns 90', () {
      // Either direction is valid (delta normalizes to -180); the
      // implementation deterministically picks the +180 deg path.
      expect(shortestArcLerpDegrees(0, 180, 0.5), closeTo(90, 1e-9));
    });

    test('t=0 returns from, t=1 returns to', () {
      expect(shortestArcLerpDegrees(45, 200, 0), closeTo(45, 1e-9));
      expect(shortestArcLerpDegrees(45, 200, 1), closeTo(200, 1e-9));
    });

    test('result is always normalized to [0, 360)', () {
      // Going through the boundary should not produce a negative or
      // >= 360 value.
      for (final t in [0.1, 0.25, 0.5, 0.75, 0.9]) {
        final v = shortestArcLerpDegrees(350, 10, t);
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThan(360));
      }
    });
  });
}
