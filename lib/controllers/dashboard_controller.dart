import 'dart:async';

import 'package:Tunyuke/screens/rides_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:Tunyuke/models/pickup_point.dart';
import 'package:Tunyuke/controllers/rides_controller.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';

class DashboardController extends ChangeNotifier {
  // Add a flag to track if the controller is disposed
  bool _isDisposed = false;

  final ValueNotifier<String> _currentTimeGreeting = ValueNotifier<String>(
    "Hey",
  );
  ValueNotifier<String> get currentTimeGreeting => _currentTimeGreeting;

  final ValueNotifier<String> _userName = ValueNotifier<String>("Guest");
  ValueNotifier<String> get userName => _userName;

  final ValueNotifier<int> _walletBalance = ValueNotifier<int>(25000);
  ValueNotifier<int> get walletBalance => _walletBalance;

  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);
  ValueNotifier<int> get currentIndex => _currentIndex;

  // Map-related properties
  final ValueNotifier<LatLng?> _userLocation = ValueNotifier<LatLng?>(null);
  ValueNotifier<LatLng?> get userLocation => _userLocation;

  final ValueNotifier<List<PickupPoint>> _pickupPoints =
      ValueNotifier<List<PickupPoint>>([]);
  ValueNotifier<List<PickupPoint>> get pickupPoints => _pickupPoints;

  final ValueNotifier<bool> _isLocationLoading = ValueNotifier<bool>(true);
  ValueNotifier<bool> get isLocationLoading => _isLocationLoading;

  final ValueNotifier<String?> _locationError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get locationError => _locationError;

  // Nearest pickup point properties
  final ValueNotifier<String?> _nearestPickupPointName = ValueNotifier<String?>(
    null,
  );
  ValueNotifier<String?> get nearestPickupPointName => _nearestPickupPointName;

  final ValueNotifier<double?> _distanceToNearestPickupPointKm =
      ValueNotifier<double?>(null);
  ValueNotifier<double?> get distanceToNearestPickupPointKm =>
      _distanceToNearestPickupPointKm;

  // Add debug information
  final ValueNotifier<String> _debugInfo = ValueNotifier<String>("");
  ValueNotifier<String> get debugInfo => _debugInfo;

  // Mock data for cards - use full paths as strings for Navigator.pushNamed
  final List<Map<String, dynamic>> dashboardCardsData = [
    {
      'icon': Icons.school_rounded,
      'title': "To Kihumuro Campus",
      'subtitle': "Morning rides 7:00-8:00 AM",
      'info': "Ready by 7:15 AM",
      'route': '/to_campus', // Use full path
      'gradientColors': [Color(0xFFFF9800), Color(0xFFFFB74D)],
    },
    {
      'icon': Icons.home_rounded,
      'title': "From Kihumuro Campus",
      'subtitle': "Evening rides 6:00-7:00 PM",
      'info': "Ready by 6:00 PM",
      'route': '/from_campus', // Use full path
      'gradientColors': [Color(0xFF3F51B5), Color(0xFF7986CB)],
    },
    {
      'icon': Icons.group_add_rounded,
      'title': "Schedule a Team Ride",
      'subtitle': "Create shared rides",
      'info': "Save up to 50%",
      'route': '/schedule_team_ride', // Use full path
      'gradientColors': [Color(0xFF4CAF50), Color(0xFF81C784)],
    },
    {
      'icon': Icons.qr_code_scanner_rounded,
      'title': "Join Scheduled Ride",
      'subtitle': "Enter referral code",
      'info': "Join existing rides",
      'route': '/onboard_scheduled_ride', // Use full path
      'gradientColors': [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    },
  ];

  final LocationService _locationService = LocationService();
  StreamSubscription<LatLng?>? _locationSubscription;

  DashboardController() {
    _initializeGreeting();
    // Fetch user name first, then initialize location
    _fetchUserNameFromFirebase().then((_) {
      _initializeLocation();
    });
  }

  void _initializeGreeting() {
    if (_isDisposed) return;
    _currentTimeGreeting.value = "Hey";
    notifyListeners();
  }

  Future<void> _fetchUserNameFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Check if disposed before updating
        if (_isDisposed) return;

        if (userDoc.exists && userDoc.data() != null) {
          String? fetchedName =
              (userDoc.data() as Map<String, dynamic>)['username'];
          if (fetchedName != null && fetchedName.isNotEmpty) {
            _userName.value = fetchedName;
          } else {
            // Try to get displayName from Firebase Auth if username is empty
            _userName.value = user.displayName ?? "User";
          }
        } else {
          // Document doesn't exist, try to get displayName from Firebase Auth
          _userName.value = user.displayName ?? "User";
        }
      } catch (e) {
        print("Error fetching user name from Firestore: $e");
        if (_isDisposed) return;
        // Fallback to displayName from Firebase Auth, not email
        _userName.value = user.displayName ?? "User";
      }
    } else {
      if (_isDisposed) return;
      _userName.value = "Guest";
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _initializeLocation() async {
    if (_isDisposed) return;

    _isLocationLoading.value = true;
    _locationError.value = null;
    _nearestPickupPointName.value = null;
    _distanceToNearestPickupPointKm.value = null;
    notifyListeners();

    try {
      // Listen to location stream
      _locationSubscription = _locationService.locationStream.listen((
        location,
      ) {
        if (_isDisposed) return;

        if (location != null) {
          _userLocation.value = location;
          _isLocationLoading.value = false;
          _locationError.value = null;
          _calculateDistancesToPickupPoints();
          _findNearestPickupPoint();
        } else {
          _isLocationLoading.value = false;
          _locationError.value = "Unable to get location";
        }
        notifyListeners();
      });

      // Fetch pickup points first
      await _fetchPickupPointsFromFirebase();
      if (_isDisposed) return;

      // Get initial location
      final location = await _locationService.getCurrentLocation();
      if (_isDisposed) return;

      if (location != null) {
        _userLocation.value = location;
        _calculateDistancesToPickupPoints();
        _findNearestPickupPoint();
      } else {
        _locationError.value = "Unable to get location";
      }

      // Start periodic updates (every 2 minutes instead of 5 seconds)
      _locationService.startLocationUpdates(interval: Duration(minutes: 2));
    } catch (e) {
      if (_isDisposed) return;
      _locationError.value = "Location error: $e";
      print("Error initializing location: $e");
    } finally {
      if (_isDisposed) return;
      _isLocationLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPickupPointsFromFirebase() async {
    if (_isDisposed) return;

    try {
      print("Fetching pickup points from Firebase...");

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pickup_points')
          .get();

      if (_isDisposed) return;

      print(
        "Firebase query completed. Documents found: ${snapshot.docs.length}",
      );

      if (snapshot.docs.isEmpty) {
        print("No pickup points found in Firebase collection 'pickup_points'");
        _debugInfo.value = "No pickup points found in Firebase";
        return;
      }

      List<PickupPoint> fetchedPoints = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print("Processing document ${doc.id}: $data");

          // Validate required fields
          if (data['name'] == null ||
              data['latitude'] == null ||
              data['longitude'] == null) {
            print("Skipping document ${doc.id} due to missing required fields");
            continue;
          }

          PickupPoint point = PickupPoint.fromFirestore(data, doc.id);
          fetchedPoints.add(point);
          print(
            "Successfully created pickup point: ${point.name} at ${point.location}",
          );
        } catch (e) {
          print("Error processing document ${doc.id}: $e");
        }
      }

      if (_isDisposed) return;
      _pickupPoints.value = fetchedPoints;
      _locationError.value = null;

      print("Successfully fetched ${fetchedPoints.length} pickup points");
      _debugInfo.value = "";
    } catch (e) {
      if (_isDisposed) return;
      _locationError.value = 'Failed to fetch pickup points: $e';
      print("Error fetching pickup points: $e");
      _debugInfo.value = "Error fetching pickup points: $e";
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _calculateDistancesToPickupPoints() {
    if (_isDisposed ||
        _userLocation.value == null ||
        _pickupPoints.value.isEmpty) {
      print(
        "Cannot calculate distances: isDisposed=$_isDisposed, userLocation=${_userLocation.value}, pickupPoints=${_pickupPoints.value.length}",
      );
      return;
    }

    final userLat = _userLocation.value!.latitude;
    final userLon = _userLocation.value!.longitude;

    List<PickupPoint> updatedPoints = [];

    for (var point in _pickupPoints.value) {
      final distance = Geolocator.distanceBetween(
        userLat,
        userLon,
        point.location.latitude,
        point.location.longitude,
      );

      updatedPoints.add(point.copyWith(distanceMeters: distance));
      print(
        "Distance to ${point.name}: ${(distance / 1000).toStringAsFixed(2)} km",
      );
    }

    _pickupPoints.value = updatedPoints;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _findNearestPickupPoint() {
    if (_isDisposed ||
        _userLocation.value == null ||
        _pickupPoints.value.isEmpty) {
      if (!_isDisposed) {
        _nearestPickupPointName.value = null;
        _distanceToNearestPickupPointKm.value = null;
      }
      return;
    }

    double minDistanceMeters = double.infinity;
    PickupPoint? nearestPoint;

    for (var point in _pickupPoints.value) {
      if (point.distanceMeters != null &&
          point.distanceMeters! < minDistanceMeters) {
        minDistanceMeters = point.distanceMeters!;
        nearestPoint = point;
      }
    }

    if (nearestPoint != null) {
      _nearestPickupPointName.value = nearestPoint.name;
      _distanceToNearestPickupPointKm.value = minDistanceMeters / 1000;
      print(
        "Nearest pickup point: ${nearestPoint.name} at ${(_distanceToNearestPickupPointKm.value! * 1000).toStringAsFixed(0)}m",
      );
    } else {
      _nearestPickupPointName.value = null;
      _distanceToNearestPickupPointKm.value = null;
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> refreshMapData() async {
    if (!_isDisposed) {
      await _initializeLocation();
    }
  }

  // Method to manually test Firebase connection
  Future<void> testFirebaseConnection() async {
    if (_isDisposed) return;

    try {
      print("Testing Firebase connection...");

      // Test basic connectivity
      QuerySnapshot testSnapshot = await FirebaseFirestore.instance
          .collection('pickup_points')
          .limit(1)
          .get();

      if (_isDisposed) return;

      print(
        "Firebase test successful. Collection exists: ${testSnapshot.docs.isNotEmpty}",
      );

      // List all documents in the collection
      QuerySnapshot allDocs = await FirebaseFirestore.instance
          .collection('pickup_points')
          .get();

      if (_isDisposed) return;

      print("All documents in pickup_points collection:");
      for (var doc in allDocs.docs) {
        print("Document ID: ${doc.id}, Data: ${doc.data()}");
      }

      _debugInfo.value =
          "Firebase test completed. Found ${allDocs.docs.length} documents.";
    } catch (e) {
      if (_isDisposed) return;
      print("Firebase test failed: $e");
      _debugInfo.value = "Firebase test failed: $e";
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void onBottomNavItemTapped(int index, BuildContext context) {
    // Don't update currentIndex when navigating to other screens
    // Only update it when staying on dashboard or returning to dashboard

    switch (index) {
      case 0:
        // Stay on dashboard - update index
        _currentIndex.value = 0;
        notifyListeners();
        break;
      case 1:
        // Navigate to rides screen - don't update currentIndex
        // Keep it at 0 so dashboard remains highlighted when we return
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: Provider.of<RidesController>(context, listen: false),
              child: const RidesScreen(),
            ),
          ),
        );
        break;
      case 2:
        // Navigate to profile - don't update currentIndex
        Navigator.pushNamed(context, '/profile');
        break;
      case 3:
        // Navigate to notifications - don't update currentIndex
        Navigator.pushNamed(context, '/notifications');
        break;
    }
  }

  void onDashboardCardTapped(BuildContext context, String routeName) {
    if (_isDisposed) return;
    Navigator.pushNamed(context, routeName);
  }

  Future<void> retryLocation() async {
    if (_isDisposed) return;

    // Use force refresh to get new location
    final location = await _locationService.getCurrentLocation(
      forceRefresh: true,
    );

    if (_isDisposed) return;

    if (location != null) {
      _userLocation.value = location;
      _locationError.value = null;
      _calculateDistancesToPickupPoints();
      _findNearestPickupPoint();
    } else {
      _locationError.value = "Unable to get location";
    }
    notifyListeners();
  }

  // Add this method
  Future<void> initializeMapDataProgressively() async {
    // Start location fetch in background
    _locationService
        .getCurrentLocation()
        .then((location) {
          if (_isDisposed) return;
          _userLocation.value = location;
          notifyListeners();

          // Once we have location, calculate distances
          if (location != null && _pickupPoints.value.isNotEmpty) {
            _calculateDistancesToPickupPoints();
            _findNearestPickupPoint();
            notifyListeners();
          }
        })
        .catchError((e) {
          print("Error getting location: $e");
        });

    // Fetch pickup points independently
    _fetchPickupPointsFromFirebase();
  }

  @override
  void dispose() {
    _isDisposed = true; // Set the flag before disposing
    _currentTimeGreeting.dispose();
    _userName.dispose();
    _walletBalance.dispose();
    _currentIndex.dispose();
    _userLocation.dispose();
    _pickupPoints.dispose();
    _isLocationLoading.dispose();
    _locationError.dispose();
    _nearestPickupPointName.dispose();
    _distanceToNearestPickupPointKm.dispose();
    _debugInfo.dispose();
    _locationSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
