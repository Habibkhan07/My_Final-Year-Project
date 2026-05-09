// Widget tests for `LiveTrackingMap`.
//
// We override `appMapBuilderProvider` with a stub that records its
// inputs, letting us assert what the LiveTrackingMap fed to the
// underlying map widget — without rendering a real provider tree.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/i_app_map.dart';
import 'package:frontend/core/widgets/map/live_tracking_map.dart';
import 'package:frontend/core/widgets/map/map_provider.dart';
import 'package:latlong2/latlong.dart';

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
    // Render a small visible widget so the LiveTrackingMap's stack
    // overlays can lay out around it.
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

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [appMapBuilderProvider.overrideWith((ref) => _stubBuilder())],
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

void main() {
  const destination = LatLng(31.5497, 74.3436);

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
    final c = _container();
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: const LatLng(31.5204, 74.3587),
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
    final c = _container();
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: const LatLng(31.5204, 74.3587),
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
      final c = _container();
      await tester.pumpWidget(
        _wrap(
          c,
          LiveTrackingMap(
            technicianPosition: const LatLng(31.5204, 74.3587),
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
    final c = _container();
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: const LatLng(31.5204, 74.3587),
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
    final c = _container();
    await tester.pumpWidget(
      _wrap(
        c,
        LiveTrackingMap(
          technicianPosition: const LatLng(31.5204, 74.3587),
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
          technicianPosition: const LatLng(31.5204, 74.3587),
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
}
