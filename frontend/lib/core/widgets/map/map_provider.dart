import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../constants.dart';
import '../../realtime/presentation/providers/dependency_injection.dart';
import 'google_app_map.dart';
import 'google_directions_service.dart';
import 'i_app_map.dart';
import 'i_directions_service.dart';
import 'osm_app_map.dart';
import 'osrm_directions_service.dart';
import 'url_launcher_port.dart';

part 'map_provider.g.dart';

/// Function that builds an [IAppMap] for the currently-active map
/// provider. `LiveTrackingMap` calls this builder with the per-frame
/// camera state instead of importing the concrete map widgets.
typedef AppMapBuilder =
    IAppMap Function({
      required LatLng initialCenter,
      double initialZoom,
      List<MapMarker> markers,
      List<MapPolyline> polylines,
      List<MapCircle> circles,
      LatLng? cameraTarget,
      double? cameraZoom,
      List<LatLng>? cameraBounds,
      VoidCallback? onUserGesture,
    });

/// Compile-time map provider — read once at app boot from
/// `--dart-define=MAP_PROVIDER`. Per-screen overriding is intentionally
/// not supported; runtime swap would force every map widget tree to
/// rebuild and re-instantiate native views.
@Riverpod(keepAlive: true)
MapProviderType mapProviderType(Ref ref) {
  final type = AppConstants.mapProvider;
  if (type == MapProviderType.google && AppConstants.googleMapsApiKey.isEmpty) {
    // flag #16 footgun — log noisily so devs notice the silent OSM
    // fallback behaviour. We return whatever the user asked for; the
    // map widget itself renders blank tiles when Google has no key,
    // which surfaces the misconfiguration visually.
    developer.log(
      'MAP_PROVIDER=google but GOOGLE_MAPS_API_KEY is empty. '
      'Google Maps will render blank tiles. Pass '
      '--dart-define=GOOGLE_MAPS_API_KEY=... at build time.',
      name: 'core.map_provider',
      level: 1000,
    );
  }
  return type;
}

/// Builder for the active map widget. Consumers receive this function
/// and construct map widgets through it; they never import OsmAppMap
/// or GoogleAppMap directly.
@Riverpod(keepAlive: true)
AppMapBuilder appMapBuilder(Ref ref) {
  final type = ref.watch(mapProviderTypeProvider);
  return switch (type) {
    MapProviderType.google =>
      ({
        required initialCenter,
        initialZoom = 15.0,
        markers = const [],
        polylines = const [],
        circles = const [],
        cameraTarget,
        cameraZoom,
        cameraBounds,
        onUserGesture,
      }) => GoogleAppMap(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        markers: markers,
        polylines: polylines,
        circles: circles,
        cameraTarget: cameraTarget,
        cameraZoom: cameraZoom,
        cameraBounds: cameraBounds,
        onUserGesture: onUserGesture,
      ),
    MapProviderType.osm =>
      ({
        required initialCenter,
        initialZoom = 15.0,
        markers = const [],
        polylines = const [],
        circles = const [],
        cameraTarget,
        cameraZoom,
        cameraBounds,
        onUserGesture,
      }) => OsmAppMap(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        markers: markers,
        polylines: polylines,
        circles: circles,
        cameraTarget: cameraTarget,
        cameraZoom: cameraZoom,
        cameraBounds: cameraBounds,
        onUserGesture: onUserGesture,
      ),
  };
}

/// Active directions service for ETA + polyline calls. Reuses the
/// existing realtime singleton `http.Client` so we don't bloat the
/// process with another connection pool just for directions.
@Riverpod(keepAlive: true)
IDirectionsService directionsService(Ref ref) {
  final client = ref.watch(eventHttpClientProvider);
  final type = ref.watch(mapProviderTypeProvider);
  return switch (type) {
    MapProviderType.google => GoogleDirectionsService(client),
    MapProviderType.osm => OsrmDirectionsService(client),
  };
}

/// URL launcher seam — `LiveTrackingMap`'s phone-call FAB delegates
/// here so widget tests can verify the snackbar fallback when the
/// dialler intent is rejected (audit H14, T-2k).
@Riverpod(keepAlive: true)
IUrlLauncher urlLauncher(Ref ref) => const UrlLauncherAdapter();
