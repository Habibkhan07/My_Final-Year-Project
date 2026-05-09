import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A consistent base for all maps in the application.
///
/// Handles tile layer configuration, user agent, and provides
/// a standard look and feel.
class AppMap extends StatelessWidget {
  final MapController? mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final List<Widget> children;
  final void Function(MapCamera, bool)? onPositionChanged;
  final void Function(MapEvent)? onMapEvent;

  const AppMap({
    super.key,
    this.mapController,
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.children = const [],
    this.onPositionChanged,
    this.onMapEvent,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        onPositionChanged: onPositionChanged,
        onMapEvent: onMapEvent,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fyp.frontend',
        ),
        ...children,
      ],
    );
  }
}
