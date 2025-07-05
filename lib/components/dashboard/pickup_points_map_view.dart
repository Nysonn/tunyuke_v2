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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
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
              ),
            ],
          ),
        ),
      );
    }

    // Create markers for all pickup points
    final Set<Marker> markers = pickupPoints
        .map((point) => point.toMarker())
        .toSet();

    // Add user's location marker if available
    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('userLocation'),
          position: userLocation!,
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ), // Blue marker for user
        ),
      );
    }

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: userLocation != null
          ? CameraPosition(
              target: userLocation!,
              zoom: 14.0, // Zoom closer if user location is known
            )
          : _kDefaultLocation, // Use default if no user location yet
      onMapCreated: onMapCreated, // Pass the controller back
      markers: markers,
      myLocationEnabled: true, // Shows blue dot for user's location
      myLocationButtonEnabled: true, // Shows button to recenter on user
      zoomControlsEnabled: false, // Hide default zoom controls
      compassEnabled: true,
    );
  }
}
