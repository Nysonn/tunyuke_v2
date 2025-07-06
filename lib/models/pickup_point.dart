import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickupPoint {
  final String id;
  final String name;
  final LatLng location;
  final double? distanceMeters;
  final bool isNearest;

  PickupPoint({
    required this.id,
    required this.name,
    required this.location,
    this.distanceMeters,
    this.isNearest = false,
  });

  // Factory constructor to create a PickupPoint from Firestore data
  factory PickupPoint.fromFirestore(Map<String, dynamic> data, String docId) {
    return PickupPoint(
      id: docId,
      name: data['name'] ?? 'Unknown Pickup Point',
      location: LatLng(
        (data['latitude'] ?? 0.0).toDouble(),
        (data['longitude'] ?? 0.0).toDouble(),
      ),
      // distanceMeters and isNearest are not from Firestore, so they're null/false initially
    );
  }

  // Enhanced copyWith method to create a new PickupPoint with updated fields
  PickupPoint copyWith({
    String? id,
    String? name,
    LatLng? location,
    double? distanceMeters,
    bool? isNearest,
  }) {
    return PickupPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isNearest: isNearest ?? this.isNearest,
    );
  }

  // Enhanced method to convert PickupPoint to a Google Maps Marker with special styling
  Marker toMarker({bool isNearestPoint = false}) {
    return Marker(
      markerId: MarkerId(id),
      position: location,
      infoWindow: InfoWindow(
        title: isNearestPoint ? '🎯 $name (Nearest)' : name,
        snippet: _getMarkerSnippet(),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isNearestPoint ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
      ),
    );
  }

  // Helper method to generate marker snippet text
  String _getMarkerSnippet() {
    if (distanceMeters != null) {
      final distanceKm = distanceMeters! / 1000;
      if (distanceKm < 1) {
        return 'Distance: ${distanceMeters!.toStringAsFixed(0)} m';
      } else {
        return 'Distance: ${distanceKm.toStringAsFixed(2)} km';
      }
    }
    return 'Pickup Point';
  }

  // Method to get formatted distance string
  String getFormattedDistance() {
    if (distanceMeters == null) return 'Distance unknown';

    final distanceKm = distanceMeters! / 1000;
    if (distanceKm < 1) {
      return '${distanceMeters!.toStringAsFixed(0)} m';
    } else {
      return '${distanceKm.toStringAsFixed(2)} km';
    }
  }

  // Method to determine walking time estimate (assuming 5 km/h walking speed)
  String getWalkingTimeEstimate() {
    if (distanceMeters == null) return 'Unknown';

    final distanceKm = distanceMeters! / 1000;
    final timeMinutes = (distanceKm / 5) * 60; // 5 km/h walking speed

    if (timeMinutes < 1) {
      return '< 1 min';
    } else if (timeMinutes < 60) {
      return '${timeMinutes.toStringAsFixed(0)} min';
    } else {
      final hours = timeMinutes / 60;
      return '${hours.toStringAsFixed(1)} hr';
    }
  }

  @override
  String toString() {
    return 'PickupPoint(id: $id, name: $name, location: $location, distanceMeters: $distanceMeters, isNearest: $isNearest)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PickupPoint &&
        other.id == id &&
        other.name == name &&
        other.location == location &&
        other.distanceMeters == distanceMeters &&
        other.isNearest == isNearest;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        location.hashCode ^
        distanceMeters.hashCode ^
        isNearest.hashCode;
  }
}
