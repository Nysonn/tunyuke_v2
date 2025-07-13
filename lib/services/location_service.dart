import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  DateTime? _lastLocationFetch;
  bool _locationRequestInProgress = false;
  StreamController<LatLng?>? _locationStreamController;
  Timer? _debounceTimer;

  // Cache location for 30 seconds
  static const Duration _cacheTimeout = Duration(seconds: 30);
  // Minimum distance change to trigger update (10 meters)
  static const double _minimumDistanceChange = 10.0;

  Stream<LatLng?> get locationStream {
    _locationStreamController ??= StreamController<LatLng?>.broadcast();
    return _locationStreamController!.stream;
  }

  Future<LatLng?> getCurrentLocation({bool forceRefresh = false}) async {
    // Return cached location if available and not expired
    if (!forceRefresh &&
        _lastKnownPosition != null &&
        _lastLocationFetch != null &&
        DateTime.now().difference(_lastLocationFetch!) < _cacheTimeout) {
      return LatLng(
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
      );
    }

    // Prevent concurrent location requests
    if (_locationRequestInProgress) {
      print('Location request already in progress, returning cached location');
      return _lastKnownPosition != null
          ? LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude)
          : null;
    }

    try {
      _locationRequestInProgress = true;

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position with timeout
      Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ).timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Location request timed out'),
          );

      // Check if location changed significantly
      bool shouldUpdate = true;
      if (_lastKnownPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        shouldUpdate = distance >= _minimumDistanceChange;
      }

      if (shouldUpdate) {
        _lastKnownPosition = position;
        _lastLocationFetch = DateTime.now();

        final latLng = LatLng(position.latitude, position.longitude);
        _locationStreamController?.add(latLng);

        print('Location updated: ${position.latitude}, ${position.longitude}');
        return latLng;
      } else {
        print('Location change too small, using cached location');
        return LatLng(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      _locationStreamController?.add(null);
      return null;
    } finally {
      _locationRequestInProgress = false;
    }
  }

  void startLocationUpdates({Duration interval = const Duration(minutes: 1)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer.periodic(interval, (timer) {
      getCurrentLocation();
    });
  }

  void stopLocationUpdates() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _locationStreamController?.close();
    _locationStreamController = null;
  }

  // Get cached location without triggering new request
  LatLng? get cachedLocation {
    return _lastKnownPosition != null
        ? LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude)
        : null;
  }

  bool get hasValidCache {
    return _lastKnownPosition != null &&
        _lastLocationFetch != null &&
        DateTime.now().difference(_lastLocationFetch!) < _cacheTimeout;
  }
}
