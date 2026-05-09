import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'app_map.dart';

/// A reusable map picker that keeps a pin fixed at the screen center.
///
/// Emits [onLocationChanged] whenever the user stops panning the map.
class LocationPicker extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final void Function(LatLng) onLocationChanged;
  final Widget? bottomCard;
  final Widget? overlay;
  final bool showCenterPin;
  final Widget? pin;
  final bool showCurrentLocationButton;

  const LocationPicker({
    super.key,
    required this.initialCenter,
    required this.onLocationChanged,
    this.initialZoom = 15.5,
    this.bottomCard,
    this.overlay,
    this.showCenterPin = true,
    this.pin,
    this.showCurrentLocationButton = true,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCenter != widget.initialCenter) {
      final currentCenter = _mapController.camera.center;
      final distance = const Distance().as(
        LengthUnit.Meter,
        currentCenter,
        widget.initialCenter,
      );

      // Only move if the widget was updated with a center far from where the map currently is
      // (e.g., from a search result, not from a map pan event).
      if (distance > 10) {
        _mapController.move(widget.initialCenter, widget.initialZoom);
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, widget.initialZoom);
      widget.onLocationChanged(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppMap(
          mapController: _mapController,
          initialCenter: widget.initialCenter,
          initialZoom: widget.initialZoom,
          onMapEvent: (event) {
            if (event is MapEventMoveEnd) {
              final center = _mapController.camera.center;
              widget.onLocationChanged(center);
            }
          },
        ),

        // Fixed centre pin
        if (widget.showCenterPin)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child:
                  widget.pin ??
                  const Icon(
                    Icons.location_pin,
                    size: 48,
                    color: Color(0xFF0051AE),
                  ),
            ),
          ),

        if (widget.overlay != null) widget.overlay!,

        if (widget.showCurrentLocationButton)
          Positioned(
            right: 16,
            bottom: widget.bottomCard != null ? 240 : 16,
            child: FloatingActionButton(
              heroTag: 'current_location_fab',
              mini: true,
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0051AE),
              child: const Icon(Icons.my_location),
            ),
          ),

        if (widget.bottomCard != null)
          Positioned(bottom: 0, left: 0, right: 0, child: widget.bottomCard!),
      ],
    );
  }
}
