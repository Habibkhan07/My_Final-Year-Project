import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'i_app_map.dart';

/// Programmatic marker icon factory.
///
/// Both providers render the same visual: a 56-logical-pixel circular
/// bubble with a coloured ring + Material icon centred. Customer is
/// green + house; technician is orange + motorbike (moving) or person
/// (stopped). Heading rotates the bubble for moving technicians.
///
/// We paint icons procedurally rather than shipping PNG assets so:
///   1. No designer round-trip blocks this session.
///   2. The visual stays crisp at all device pixel ratios (Canvas
///      does its own anti-aliasing per call).
///   3. Re-skinning later (custom truck, branded colours) is one
///      function in this file, not a sprawl through asset folders.
///
/// **Caching.** `BitmapDescriptor` build is async (Canvas → PNG bytes
/// → descriptor). The Google adapter caches by `MarkerKind` so the
/// 5s GPS frames don't repaint the same icon endlessly. The cache is
/// keyed only on kind because rotation goes through `gmaps.Marker.rotation`
/// (Google rotates the bitmap for us — no need for per-angle bitmaps).
class LiveMarkerFactory {
  LiveMarkerFactory._();

  // ─── Visual constants (single source of truth for both providers) ──

  /// Logical-pixel bubble diameter. Big enough for older eyes / fat
  /// fingers per the illiterate-user UX brief.
  static const double bubbleDiameter = 56.0;

  static const double _ringWidth = 3.0;
  static const double _iconSize = 30.0;

  static const Color _customerRing = Color(0xFF1B873F); // material green 700ish
  static const Color _technicianRing = Color(0xFFEF6C00); // material orange 800
  static const Color _bubbleFill = Colors.white;
  static const Color _customerIcon = Color(0xFF1B873F);
  static const Color _technicianIcon = Color(0xFFEF6C00);

  /// Test-only key — see `buildOsmMarker` rotation branch.
  @visibleForTesting
  static const headingRotationKey = ValueKey('live_marker_heading_rotation');

  // ─── OSM (flutter_map) — Widget-based markers ──────────────────────

  /// Builds the marker as a Flutter [Widget]. Used by [OsmAppMap]'s
  /// `MarkerLayer`. Rotation is applied here (flutter_map's `Marker`
  /// has no `rotation` prop).
  static Widget buildOsmMarker(MapMarker marker) {
    final iconData = _iconFor(marker.kind);
    final ringColor = _ringFor(marker.kind);
    final iconColor = _iconColorFor(marker.kind);

    Widget bubble = Container(
      width: bubbleDiameter,
      height: bubbleDiameter,
      decoration: BoxDecoration(
        color: _bubbleFill,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: _ringWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(iconData, color: iconColor, size: _iconSize),
    );

    if (marker.kind == MarkerKind.technicianMoving &&
        marker.rotationDegrees != 0.0) {
      // Convert degrees → radians. Material `Transform.rotate` takes
      // radians; positive = clockwise. The ValueKey is testability-only —
      // tests use `find.byKey(headingRotationKey)` to assert the rotation
      // wrapper is (or is not) present, since `find.byType(Transform)`
      // would also match material's internal `Transform`s.
      final radians = marker.rotationDegrees * math.pi / 180.0;
      bubble = Transform.rotate(
        key: headingRotationKey,
        angle: radians,
        child: bubble,
      );
    }

    return bubble;
  }

  // ─── Google Maps — BitmapDescriptor cache ──────────────────────────
  //
  // Audit M-1: drop shadow on the bubble (OSM had it via `BoxShadow`;
  // Google painter previously had none — flat-vs-raised inconsistency).
  // Audit M-2: align the painted fill / ring geometry so both providers
  // visually match (ring outer = container edge, fill goes to ring
  // inner edge, ring stroke covers the gap on top).
  // Audit M-3: cache key now includes devicePixelRatio so a 3x device
  // doesn't reuse a 2x-rendered descriptor (would render visibly small
  // on 3x phones). Cheap memory cost — one descriptor per kind per
  // distinct dpr the device is asked to render at (typically 1).
  // Audit M-4: pass `imagePixelRatio` to `BitmapDescriptor.bytes` so
  // Google Maps scales the bitmap down to logical pixels. Pre-fix, the
  // bitmap defaulted to 1.0 dpr — a 3x device showed a marker 3x its
  // intended logical size.

  // MF-1 (Batch I): cache stores the in-flight `Future`, not the
  // resolved descriptor. Without this, two concurrent callers (e.g.
  // GoogleAppMap's `_resolveAllMarkers` resolving customer + technician
  // markers in parallel via `Future.wait`) would both miss the cache,
  // both render to canvas → PNG (the expensive op), and one overwrite
  // the other's entry. `putIfAbsent` makes resolution single-flight:
  // exactly one paint per (kind, dpr) regardless of concurrency.
  static final Map<({MarkerKind kind, double dpr}),
      Future<gmaps.BitmapDescriptor>> _cache = {};

  /// Lazily builds (and caches) a [gmaps.BitmapDescriptor] for [kind]
  /// at the supplied [devicePixelRatio]. First call per (kind, dpr)
  /// paints to a `Canvas` and converts the result to PNG bytes;
  /// subsequent calls return the cached descriptor.
  ///
  /// Rotation is NOT baked in — Google's `Marker.rotation` rotates the
  /// bitmap natively. Two calls with different rotations on the same
  /// kind+dpr both share one descriptor.
  static Future<gmaps.BitmapDescriptor> buildGoogleMarker(
    MarkerKind kind, {
    double devicePixelRatio = 2.0,
  }) {
    final key = (kind: kind, dpr: devicePixelRatio);
    return _cache.putIfAbsent(
      key,
      () => _paintGoogleMarker(kind, devicePixelRatio),
    );
  }

  static Future<gmaps.BitmapDescriptor> _paintGoogleMarker(
    MarkerKind kind,
    double devicePixelRatio,
  ) async {
    final size = bubbleDiameter * devicePixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final centre = Offset(size / 2, size / 2);
    final ringWidthPx = _ringWidth * devicePixelRatio;
    // Ring outer = container edge (size/2). Ring center radius is one
    // half-stroke inside; ring inner radius is one full stroke inside.
    // Fill is painted to ring INNER radius so the ring stroke (drawn
    // on top, centered on `ringCenterRadius`) cleanly covers the gap.
    // Mirrors OSM's `Container(56) + Border.all(3)` semantics.
    final ringOuterRadius = size / 2;
    final ringCenterRadius = ringOuterRadius - ringWidthPx / 2;
    final fillRadius = ringOuterRadius - ringWidthPx;

    // Audit M-1: drop shadow under the bubble. Mirror OSM's
    // BoxShadow(color: 0x33000000, blurRadius: 6, offset: (0, 2)).
    // Sigma = blurRadius / 2 for Material parity.
    canvas.drawCircle(
      Offset(centre.dx, centre.dy + 2 * devicePixelRatio),
      ringOuterRadius,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          3 * devicePixelRatio,
        ),
    );

    // Fill (extends to ring inner edge).
    canvas.drawCircle(centre, fillRadius, Paint()..color = _bubbleFill);

    // Ring (stroke centered on `ringCenterRadius`, covering the area
    // from fillRadius to ringOuterRadius).
    canvas.drawCircle(
      centre,
      ringCenterRadius,
      Paint()
        ..color = _ringFor(kind)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidthPx,
    );

    // Icon. We render the IconData glyph through TextPainter — same
    // glyph the OSM bubble shows, no asset round-trip.
    final iconData = _iconFor(kind);
    final iconPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: _iconSize * devicePixelRatio,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: _iconColorFor(kind),
        ),
      )
      ..layout();
    iconPainter.paint(
      canvas,
      Offset((size - iconPainter.width) / 2, (size - iconPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    image.dispose();
    // Audit M-4: explicit `imagePixelRatio` so Google Maps renders the
    // bitmap at `bubbleDiameter` logical pixels regardless of the host
    // device's pixel ratio.
    return gmaps.BitmapDescriptor.bytes(
      Uint8List.fromList(bytes),
      imagePixelRatio: devicePixelRatio,
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  static IconData _iconFor(MarkerKind kind) => switch (kind) {
    MarkerKind.customer => Icons.home_filled,
    MarkerKind.technicianMoving => Icons.two_wheeler,
    MarkerKind.technicianStopped => Icons.directions_walk,
  };

  static Color _ringFor(MarkerKind kind) => switch (kind) {
    MarkerKind.customer => _customerRing,
    MarkerKind.technicianMoving ||
    MarkerKind.technicianStopped => _technicianRing,
  };

  static Color _iconColorFor(MarkerKind kind) => switch (kind) {
    MarkerKind.customer => _customerIcon,
    MarkerKind.technicianMoving ||
    MarkerKind.technicianStopped => _technicianIcon,
  };

  /// Test-only: drops cached descriptors. Production code never needs
  /// this — the cache is correct-by-construction.
  @visibleForTesting
  static void clearCache() => _cache.clear();
}
