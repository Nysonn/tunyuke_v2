import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Utility class for location-related calculations
class LocationUtils {
  // Earth's radius in kilometers
  static const double _earthRadiusKm = 6371.0;

  /// Calculates the distance between two LatLng points using the Haversine formula.
  /// Returns the distance in kilometers.
  static double calculateDistance(LatLng latLng1, LatLng latLng2) {
    final lat1Rad = _degreesToRadians(latLng1.latitude);
    final lon1Rad = _degreesToRadians(latLng1.longitude);
    final lat2Rad = _degreesToRadians(latLng2.latitude);
    final lon2Rad = _degreesToRadians(latLng2.longitude);

    final deltaLat = lat2Rad - lat1Rad;
    final deltaLon = lon2Rad - lon1Rad;

    final a =
        pow(sin(deltaLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
