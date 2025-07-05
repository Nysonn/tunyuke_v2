import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickupPoint {
  final String id;
  final String name;
  final LatLng location;
  double?
  distanceMeters; // Distance from user to this point (optional, calculated)

  PickupPoint({
    required this.id,
    required this.name,
    required this.location,
    this.distanceMeters,
  });

  // Factory constructor to create a PickupPoint from Firestore data
  factory PickupPoint.fromFirestore(Map<String, dynamic> data, String id) {
    return PickupPoint(
      id: id,
      name: data['name'] ?? 'Unknown Pickup Point',
      location: LatLng(
        data['latitude']?.toDouble() ?? 0.0,
        data['longitude']?.toDouble() ?? 0.0,
      ),
    );
  }

  // Method to create a Marker for this PickupPoint
  Marker toMarker() {
    return Marker(
      markerId: MarkerId(id),
      position: location,
      infoWindow: InfoWindow(
        title: name,
        snippet: distanceMeters != null
            ? '${(distanceMeters! / 1000).toStringAsFixed(2)} km away'
            : 'Calculating distance...',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      ), // Customize marker color
    );
  }

  // Method to update distance (for when user location is known)
  PickupPoint copyWith({double? distanceMeters}) {
    return PickupPoint(
      id: this.id,
      name: this.name,
      location: this.location,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
