import 'dart:async';

import 'package:Tunyuke/screens/rides_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:Tunyuke/models/pickup_point.dart';
import 'package:Tunyuke/controllers/rides_controller.dart'; // Import the RidesController
import 'package:provider/provider.dart';

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

  DashboardController() {
    _initializeGreeting();
    _fetchUserNameFromFirebase();
    _initializeLocationAndMapData();
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
            _userName.value = "User";
          }
        } else {
          _userName.value = "New User";
        }
      } catch (e) {
        print("Error fetching user name from Firestore: $e");
        // Check if disposed before updating
        if (_isDisposed) return;
        _userName.value = "Error User";
      }
    } else {
      // Check if disposed before updating
      if (_isDisposed) return;
      _userName.value = "Guest";
    }

    // Only notify listeners if not disposed
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _initializeLocationAndMapData() async {
    if (_isDisposed) return;

    _isLocationLoading.value = true;
    _locationError.value = null;
    _nearestPickupPointName.value = null;
    _distanceToNearestPickupPointKm.value = null;
    _debugInfo.value = "Initializing location and map data...";
    notifyListeners();

    try {
      // Get user's location first
      await _determinePosition();

      // Check if disposed after async operation
      if (_isDisposed) return;

      // Then fetch pickup points
      await _fetchPickupPointsFromFirebase();

      // Check if disposed after async operation
      if (_isDisposed) return;

      // Calculate distances and find nearest
      if (_userLocation.value != null && _pickupPoints.value.isNotEmpty) {
        _calculateDistancesToPickupPoints();
        _findNearestPickupPoint();
        _debugInfo.value = "";
      } else {
        _debugInfo.value = "";
      }
    } catch (e) {
      if (_isDisposed) return;
      _debugInfo.value = "";
    } finally {
      if (_isDisposed) return;
      _isLocationLoading.value = false;
      _startPeriodicUpdates(); // Start periodic updates after initialization
      notifyListeners();
    }
  }

  Future<void> _determinePosition() async {
    if (_isDisposed) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (_isDisposed) return;
        _locationError.value =
            'Location services are disabled. Please enable them.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (_isDisposed) return;
          _locationError.value = 'Location permissions are denied.';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (_isDisposed) return;
        _locationError.value =
            'Location permissions are permanently denied, we cannot request permissions.';
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10), // Add timeout
      );

      if (_isDisposed) return;
      _userLocation.value = LatLng(position.latitude, position.longitude);
      _locationError.value = null;
      print("User location found: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      if (_isDisposed) return;
      _locationError.value = 'Failed to get current location: $e';
      print('Error getting current location: $e');
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Timers for periodic updates
  Timer? _pickupPointsTimer;
  Timer? _locationTimer;

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

  void _startPeriodicUpdates() {
    if (_isDisposed) return;

    // Cancel existing timers if any
    _stopPeriodicUpdates();

    // Start periodic location updates every 5 seconds
    _locationTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (!_isDisposed) {
        _determinePosition();
      }
    });

    // Start periodic pickup points updates every 5 seconds
    _pickupPointsTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (!_isDisposed) {
        await _fetchPickupPointsFromFirebase();
        if (_userLocation.value != null && _pickupPoints.value.isNotEmpty) {
          _calculateDistancesToPickupPoints();
          _findNearestPickupPoint();
        }
      }
    });
  }

  void _stopPeriodicUpdates() {
    _locationTimer?.cancel();
    _pickupPointsTimer?.cancel();
  }

  @override
  void dispose() {
    _isDisposed = true; // Set the flag before disposing
    _stopPeriodicUpdates();
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
    super.dispose();
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
      await _initializeLocationAndMapData();
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
    _currentIndex.value = index;
    notifyListeners();

    switch (index) {
      case 0:
        // Stay on dashboard - no navigation needed
        break;
      case 1:
        // Navigate to rides screen with the provider context (Solution 1)
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
        // Navigate to profile
        Navigator.pushNamed(context, '/profile');
        break;
      case 3:
        // Navigate to notifications
        Navigator.pushNamed(context, '/notifications');
        break;
    }
  }

  void onDashboardCardTapped(BuildContext context, String routeName) {
    if (_isDisposed) return;
    Navigator.pushNamed(context, routeName);
  }
}
