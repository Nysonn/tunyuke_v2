import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:Tunyuke/models/pickup_point.dart';

class IsolatedMapWidget extends StatefulWidget {
  final LatLng? userLocation;
  final List<PickupPoint> pickupPoints;
  final Function(GoogleMapController) onMapCreated;

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(-0.6118643031817739, 30.637993719602537),
    zoom: 12,
  );

  const IsolatedMapWidget({
    super.key,
    required this.userLocation,
    required this.pickupPoints,
    required this.onMapCreated,
  });

  @override
  _IsolatedMapWidgetState createState() => _IsolatedMapWidgetState();
}

class _IsolatedMapWidgetState extends State<IsolatedMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _updateMarkersAndPolylines();
  }

  @override
  void didUpdateWidget(IsolatedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if there are meaningful changes
    bool shouldUpdate = false;

    // Check if user location changed significantly (more than 10 meters)
    if (oldWidget.userLocation != widget.userLocation) {
      if (oldWidget.userLocation == null || widget.userLocation == null) {
        shouldUpdate = true;
      } else {
        final distance = _calculateDistance(
          oldWidget.userLocation!,
          widget.userLocation!,
        );
        if (distance > 10) {
          // Only update if moved more than 10 meters
          shouldUpdate = true;
        }
      }
    }

    // Check if pickup points changed
    if (oldWidget.pickupPoints.length != widget.pickupPoints.length) {
      shouldUpdate = true;
    }

    if (shouldUpdate) {
      _updateMarkersAndPolylines();
      _updateCamera();
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation (not perfectly accurate but good enough)
    final lat1Rad = point1.latitude * (3.14159 / 180);
    final lat2Rad = point2.latitude * (3.14159 / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (3.14159 / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (3.14159 / 180);
    final a =
        (deltaLat / 2).abs() * (deltaLat / 2).abs() +
        cos(lat1Rad) *
            cos(lat2Rad) *
            (deltaLng / 2).abs() *
            (deltaLng / 2).abs();
    final c = 2 * asin(sqrt(a));

    return 6371000 * c; // Earth's radius in meters
  }

  void _updateMarkersAndPolylines() {
    final newMarkers = <Marker>{};

    // Add user location marker
    if (widget.userLocation != null) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: widget.userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add pickup point markers
    newMarkers.addAll(
      widget.pickupPoints.map((point) => point.toMarker()).toSet(),
    );

    setState(() {
      _markers = newMarkers;
      _polylines = _createPolylines();
    });
  }

  void _updateCamera() {
    if (_mapController != null && widget.userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: widget.userLocation!, zoom: 14.0),
        ),
      );
    }
  }

  PickupPoint? _findNearestPickupPoint() {
    if (widget.userLocation == null || widget.pickupPoints.isEmpty) return null;

    PickupPoint? nearest;
    double minDistance = double.infinity;

    for (var point in widget.pickupPoints) {
      if (point.distanceMeters != null && point.distanceMeters! < minDistance) {
        minDistance = point.distanceMeters!;
        nearest = point;
      }
    }

    return nearest;
  }

  Set<Polyline> _createPolylines() {
    if (widget.userLocation == null) return {};

    final nearestPoint = _findNearestPickupPoint();
    if (nearestPoint == null) return {};

    return {
      Polyline(
        polylineId: PolylineId('route_to_nearest'),
        points: [widget.userLocation!, nearestPoint.location],
        color: Colors.blue,
        width: 4,
        patterns: [],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: widget.userLocation != null
          ? CameraPosition(target: widget.userLocation!, zoom: 14.0)
          : IsolatedMapWidget._kDefaultLocation,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapCreated(controller);
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
