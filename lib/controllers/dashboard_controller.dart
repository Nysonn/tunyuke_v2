import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardController extends ChangeNotifier {
  final ValueNotifier<String> _currentTimeGreeting = ValueNotifier<String>(
    "Hey",
  );
  ValueNotifier<String> get currentTimeGreeting => _currentTimeGreeting;

  final ValueNotifier<String> _userName = ValueNotifier<String>(
    "there",
  ); // Default to Guest
  ValueNotifier<String> get userName => _userName;

  final ValueNotifier<int> _walletBalance = ValueNotifier<int>(25000);
  ValueNotifier<int> get walletBalance => _walletBalance;

  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);
  ValueNotifier<int> get currentIndex => _currentIndex;

  // Mock data for cards - this could eventually come from a service
  final List<Map<String, dynamic>> dashboardCardsData = [
    {
      'icon': Icons.school_rounded,
      'title': "To Kihumuro Campus",
      'subtitle': "Morning rides 7:00-8:00 AM",
      'info': "Ready by 7:15 AM",
      'route': '/to_campus',
      'gradientColors': [
        Color(0xFFFF9800), // Orange for morning
        Color(0xFFFFB74D),
      ],
    },
    {
      'icon': Icons.home_rounded,
      'title': "From Kihumuro Campus",
      'subtitle': "Evening rides 6:00-7:00 PM",
      'info': "Ready by 6:00 PM",
      'route': '/from_campus',
      'gradientColors': [
        Color(0xFF3F51B5), // Blue for evening
        Color(0xFF7986CB),
      ],
    },
    {
      'icon': Icons.group_add_rounded,
      'title': "Schedule a Team Ride",
      'subtitle': "Create shared rides",
      'info': "Save up to 50%",
      'route': '/schedule_team_ride',
      'gradientColors': [
        Color(0xFF4CAF50), // Green for savings
        Color(0xFF81C784),
      ],
    },
    {
      'icon': Icons.qr_code_scanner_rounded,
      'title': "Join Scheduled Ride",
      'subtitle': "Enter referral code",
      'info': "Join existing rides",
      'route': '/onboard_scheduled_ride',
      'gradientColors': [
        Color(0xFF9C27B0), // Purple for community
        Color(0xFFBA68C8),
      ],
    },
  ];

  DashboardController() {
    _initializeGreeting();
    _fetchUserNameFromFirebase(); // Call the new method to fetch the user name
  }

  void _initializeGreeting() {
    // Set static greeting instead of time-based
    _currentTimeGreeting.value = "Hey";
    notifyListeners();
  }

  Future<void> _fetchUserNameFromFirebase() async {
    final user =
        FirebaseAuth.instance.currentUser; // Get current authenticated user

    if (user != null) {
      try {
        // Fetch user document from Firestore using their UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          // Check if 'username' field exists and update _userName
          String? fetchedName =
              (userDoc.data() as Map<String, dynamic>)['username'];
          if (fetchedName != null && fetchedName.isNotEmpty) {
            _userName.value = fetchedName;
          } else {
            _userName.value =
                "User"; // Fallback if username is empty or null in Firestore
          }
        } else {
          _userName.value =
              "New User"; // Fallback if user document doesn't exist
        }
      } catch (e) {
        print("Error fetching user name from Firestore: $e");
        _userName.value = "Error User"; // Fallback on error
      }
    } else {
      _userName.value = "Guest"; // No user logged in
    }
    notifyListeners(); // Notify UI that the username has been updated
  }

  void onBottomNavItemTapped(int index, BuildContext context) {
    _currentIndex.value = index;
    notifyListeners();

    // Handle navigation based on index
    switch (index) {
      case 0:
        // Stay on dashboard
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

  // Optional: Method to update user name if needed (e.g., after profile edit)
  void updateUserName(String newName) {
    _userName.value = newName;
    notifyListeners();
  }

  // Optional: Method to update greeting if needed
  void updateGreeting(String newGreeting) {
    _currentTimeGreeting.value = newGreeting;
    notifyListeners();
  }
}
