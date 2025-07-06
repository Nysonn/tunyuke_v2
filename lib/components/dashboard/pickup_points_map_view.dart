import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:Tunyuke/models/pickup_point.dart';

class PickupPointsMapView extends StatelessWidget {
  final bool isLoading;
  final String? locationError;
  final LatLng? userLocation;
  final List<PickupPoint> pickupPoints;
  final VoidCallback onRetryLocation;
  final Function(GoogleMapController) onMapCreated;

  // Default camera position if user location is not available (e.g., Kampala)
  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(0.313611, 32.581111), // Roughly Kampala, Uganda
    zoom: 12,
  );

  const PickupPointsMapView({
    Key? key,
    required this.isLoading,
    required this.locationError,
    required this.userLocation,
    required this.pickupPoints,
    required this.onRetryLocation,
    required this.onMapCreated,
  }) : super(key: key);

  /// Find the nearest pickup point to the user's location
  PickupPoint? _findNearestPickupPoint() {
    if (userLocation == null || pickupPoints.isEmpty) return null;

    PickupPoint? nearest;
    double minDistance = double.infinity;

    for (var point in pickupPoints) {
      if (point.distanceMeters != null && point.distanceMeters! < minDistance) {
        minDistance = point.distanceMeters!;
        nearest = point;
      }
    }

    return nearest;
  }

  /// Create a polyline from user location to nearest pickup point
  Set<Polyline> _createPolylines() {
    if (userLocation == null) return {};

    final nearestPoint = _findNearestPickupPoint();
    if (nearestPoint == null) return {};

    return {
      Polyline(
        polylineId: PolylineId('route_to_nearest'),
        points: [userLocation!, nearestPoint.location],
        color: Colors.blue,
        width: 4,
        patterns: [], // Solid line
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  /// Create markers for all pickup points with special styling for nearest
  Set<Marker> _createMarkers() {
    final Set<Marker> markers = {};
    final nearestPoint = _findNearestPickupPoint();

    // Add pickup point markers
    for (var point in pickupPoints) {
      final isNearest = nearestPoint != null && point.id == nearestPoint.id;

      markers.add(
        Marker(
          markerId: MarkerId(point.id),
          position: point.location,
          infoWindow: InfoWindow(
            title: isNearest ? '🎯 ${point.name} (Nearest)' : point.name,
            snippet: point.distanceMeters != null
                ? 'Distance: ${(point.distanceMeters! / 1000).toStringAsFixed(2)} km'
                : 'Pickup Point',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isNearest ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    // Add user's location marker
    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('userLocation'),
          position: userLocation!,
          infoWindow: InfoWindow(
            title: '📍 Your Location',
            snippet: nearestPoint != null
                ? 'Nearest: ${nearestPoint.name}'
                : 'Your current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  /// Calculate the appropriate camera bounds to show both user location and nearest pickup point
  CameraPosition _calculateOptimalCamera() {
    if (userLocation == null) return _kDefaultLocation;

    final nearestPoint = _findNearestPickupPoint();
    if (nearestPoint == null) {
      return CameraPosition(target: userLocation!, zoom: 14.0);
    }

    // Calculate bounds that include both user location and nearest pickup point
    final double minLat = [
      userLocation!.latitude,
      nearestPoint.location.latitude,
    ].reduce((a, b) => a < b ? a : b);
    final double maxLat = [
      userLocation!.latitude,
      nearestPoint.location.latitude,
    ].reduce((a, b) => a > b ? a : b);
    final double minLng = [
      userLocation!.longitude,
      nearestPoint.location.longitude,
    ].reduce((a, b) => a < b ? a : b);
    final double maxLng = [
      userLocation!.longitude,
      nearestPoint.location.longitude,
    ].reduce((a, b) => a > b ? a : b);

    // Calculate center point
    final double centerLat = (minLat + maxLat) / 2;
    final double centerLng = (minLng + maxLng) / 2;

    // Calculate appropriate zoom level based on distance
    final double distance = nearestPoint.distanceMeters ?? 1000;
    double zoom = 14.0;

    if (distance < 500) {
      zoom = 16.0;
    } else if (distance < 1000) {
      zoom = 15.0;
    } else if (distance < 2000) {
      zoom = 14.0;
    } else if (distance < 5000) {
      zoom = 13.0;
    } else {
      zoom = 12.0;
    }

    return CameraPosition(target: LatLng(centerLat, centerLng), zoom: zoom);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading map data...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                locationError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onRetryLocation,
                icon: Icon(Icons.refresh),
                label: Text("Retry Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final markers = _createMarkers();
    final polylines = _createPolylines();
    final cameraPosition = _calculateOptimalCamera();

    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: cameraPosition,
          onMapCreated: onMapCreated,
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          buildingsEnabled: true,
          trafficEnabled: false,
        ),

        // Map legend
        if (userLocation != null && _findNearestPickupPoint() != null)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 3, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        'Route to nearest',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Nearest pickup',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Distance indicator
        if (_findNearestPickupPoint() != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_walk, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    '${(_findNearestPickupPoint()!.distanceMeters! / 1000).toStringAsFixed(2)} km',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
