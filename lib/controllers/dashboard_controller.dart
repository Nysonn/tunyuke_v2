import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // For location services
import 'package:Tunyuke/models/pickup_point.dart'; // Import our new model

class DashboardController extends ChangeNotifier {
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

  // --- Map-related properties ---
  final ValueNotifier<LatLng?> _userLocation = ValueNotifier<LatLng?>(null);
  ValueNotifier<LatLng?> get userLocation => _userLocation;

  final ValueNotifier<List<PickupPoint>> _pickupPoints =
      ValueNotifier<List<PickupPoint>>([]);
  ValueNotifier<List<PickupPoint>> get pickupPoints => _pickupPoints;

  final ValueNotifier<bool> _isLocationLoading = ValueNotifier<bool>(true);
  ValueNotifier<bool> get isLocationLoading => _isLocationLoading;

  final ValueNotifier<String?> _locationError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get locationError => _locationError;

  // Mock data for cards (existing)
  final List<Map<String, dynamic>> dashboardCardsData = [
    {
      'icon': Icons.school_rounded,
      'title': "To Kihumuro Campus",
      'subtitle': "Morning rides 7:00-8:00 AM",
      'info': "Ready by 7:15 AM",
      'route': '/to_campus',
      'gradientColors': [Color(0xFFFF9800), Color(0xFFFFB74D)],
    },
    {
      'icon': Icons.home_rounded,
      'title': "From Kihumuro Campus",
      'subtitle': "Evening rides 6:00-7:00 PM",
      'info': "Ready by 6:00 PM",
      'route': '/from_campus',
      'gradientColors': [Color(0xFF3F51B5), Color(0xFF7986CB)],
    },
    {
      'icon': Icons.group_add_rounded,
      'title': "Schedule a Team Ride",
      'subtitle': "Create shared rides",
      'info': "Save up to 50%",
      'route': '/schedule_team_ride',
      'gradientColors': [Color(0xFF4CAF50), Color(0xFF81C784)],
    },
    {
      'icon': Icons.qr_code_scanner_rounded,
      'title': "Join Scheduled Ride",
      'subtitle': "Enter referral code",
      'info': "Join existing rides",
      'route': '/onboard_scheduled_ride',
      'gradientColors': [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    },
  ];

  DashboardController() {
    _initializeGreeting();
    _fetchUserNameFromFirebase();
    _initializeLocationAndMapData(); // New initialization for map data
  }

  void _initializeGreeting() {
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
        _userName.value = "Error User";
      }
    } else {
      _userName.value = "Guest";
    }
    notifyListeners();
  }

  // --- New Map-related methods ---

  Future<void> _initializeLocationAndMapData() async {
    _isLocationLoading.value = true;
    _locationError.value = null;
    notifyListeners();

    await _determinePosition(); // Get user's location first
    await _fetchPickupPointsFromFirebase(); // Then fetch pickup points
    _calculateDistancesToPickupPoints(); // Calculate distances once both are available

    _isLocationLoading.value = false;
    notifyListeners();
  }

  /// Determine the current position of the device.
  /// When permissions are not granted, the `locationError` will be set.
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationError.value =
          'Location services are disabled. Please enable them.';
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationError.value = 'Location permissions are denied.';
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationError.value =
          'Location permissions are permanently denied, we cannot request permissions.';
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high, // High accuracy for ride-sharing
      );
      _userLocation.value = LatLng(position.latitude, position.longitude);
      _locationError.value = null; // Clear any previous error
    } catch (e) {
      _locationError.value = 'Failed to get current location: $e';
      print('Error getting current location: $e');
    }
    notifyListeners();
  }

  Future<void> _fetchPickupPointsFromFirebase() async {
    try {
      // Assuming you have a collection named 'pickup_points' in Firestore
      // with documents containing 'name', 'latitude', 'longitude'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pickup_points')
          .get();

      List<PickupPoint> fetchedPoints = snapshot.docs.map((doc) {
        return PickupPoint.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      _pickupPoints.value = fetchedPoints;
      _locationError.value = null; // Clear error if successful
    } catch (e) {
      _locationError.value = 'Failed to fetch pickup points: $e';
      print("Error fetching pickup points: $e");
    }
    notifyListeners();
  }

  void _calculateDistancesToPickupPoints() {
    if (_userLocation.value == null || _pickupPoints.value.isEmpty) {
      return; // Cannot calculate without user location or pickup points
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
    }
    _pickupPoints.value = updatedPoints;
    notifyListeners();
  }

  /// Refreshes user location and pickup points data
  ///
  /// This can be called from a pull-to-refresh or manual refresh button
  /// to update the user's current location and fetch the latest pickup points
  /// from Firebase. It will also recalculate distances between the user and
  /// pickup points.
  Future<void> refreshMapData() async {
    await _initializeLocationAndMapData();
  }

  // --- Existing methods ---

  void onBottomNavItemTapped(int index, BuildContext context) {
    _currentIndex.value = index;
    notifyListeners();

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/ride_history');
        break;
      case 2:
        Navigator.pushNamed(context, '/wallet');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  void onDashboardCardTapped(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  void dispose() {
    _currentTimeGreeting.dispose();
    _userName.dispose();
    _walletBalance.dispose();
    _currentIndex.dispose();
    _userLocation.dispose(); // Dispose map related notifiers
    _pickupPoints.dispose();
    _isLocationLoading.dispose();
    _locationError.dispose();
    super.dispose();
  }
}
