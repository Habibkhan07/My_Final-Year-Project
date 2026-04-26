import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'app_map.dart';

/// A non-interactive (fully locked) map thumbnail centred on [lat]/[lng].
///
/// Built on [AppMap]. To migrate to Google Maps SDK: replace the body of this
/// file only — the interface (lat, lng, zoom, height, borderRadius) is frozen
/// and all call-sites stay untouched.
///
/// IgnorePointer ensures the map captures zero touch events, so the parent
/// scroll view owns all drag/swipe gestures — the technician cannot
/// accidentally scroll the map instead of the page.
class JobLocationMap extends StatelessWidget {
  const JobLocationMap({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 15.0,
    this.height = 140.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double lat;
  final double lng;
  final double zoom;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        child: IgnorePointer(
          child: AppMap(
            initialCenter: LatLng(lat, lng),
            initialZoom: zoom,
            children: const [_CentrePin()],
          ),
        ),
      ),
    );
  }
}

/// A simple centre-pin marker so the technician can see the exact job location
/// without any user interaction.
class _CentrePin extends StatelessWidget {
  const _CentrePin();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.location_pin, color: Color(0xFF2563EB), size: 36),
    );
  }
}
