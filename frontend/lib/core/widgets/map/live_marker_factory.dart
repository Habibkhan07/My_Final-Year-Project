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
      final radians = marker.rotationDegrees * 3.141592653589793 / 180.0;
      bubble = Transform.rotate(
        key: headingRotationKey,
        angle: radians,
        child: bubble,
      );
    }

    return bubble;
  }

  // ─── Google Maps — BitmapDescriptor cache ──────────────────────────

  static final Map<MarkerKind, gmaps.BitmapDescriptor> _cache = {};

  /// Lazily builds (and caches) a [gmaps.BitmapDescriptor] for [kind].
  /// First call per kind paints to a `Canvas` and converts the result
  /// to PNG bytes; subsequent calls return the cached descriptor.
  ///
  /// Rotation is NOT baked in — Google's `Marker.rotation` rotates the
  /// bitmap natively. Two calls with different rotations on the same
  /// kind both share one descriptor.
  static Future<gmaps.BitmapDescriptor> buildGoogleMarker(
    MarkerKind kind, {
    double devicePixelRatio = 2.0,
  }) async {
    final cached = _cache[kind];
    if (cached != null) return cached;

    final descriptor = await _paintGoogleMarker(kind, devicePixelRatio);
    _cache[kind] = descriptor;
    return descriptor;
  }

  static Future<gmaps.BitmapDescriptor> _paintGoogleMarker(
    MarkerKind kind,
    double devicePixelRatio,
  ) async {
    final size = bubbleDiameter * devicePixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fill bubble.
    final centre = Offset(size / 2, size / 2);
    final bubbleRadius = size / 2 - (_ringWidth * devicePixelRatio / 2);

    canvas.drawCircle(centre, bubbleRadius, Paint()..color = _bubbleFill);

    // Ring.
    canvas.drawCircle(
      centre,
      bubbleRadius,
      Paint()
        ..color = _ringFor(kind)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth * devicePixelRatio,
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
    return gmaps.BitmapDescriptor.bytes(Uint8List.fromList(bytes));
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
