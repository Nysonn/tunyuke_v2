import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UserRide {
  final String id;
  final String creatorUid;
  final int seats;
  final DateTime scheduledAt;
  final String? pickupPointId;
  final String pickupName;
  final double pickupLat;
  final double pickupLng;
  final String? destPointId;
  final String destName;
  final double destLat;
  final double destLng;
  final String referralCode;
  final DateTime codeExpiresAt;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int participantsCount;

  UserRide({
    required this.id,
    required this.creatorUid,
    required this.seats,
    required this.scheduledAt,
    this.pickupPointId,
    required this.pickupName,
    required this.pickupLat,
    required this.pickupLng,
    this.destPointId,
    required this.destName,
    required this.destLat,
    required this.destLng,
    required this.referralCode,
    required this.codeExpiresAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.participantsCount,
  });

  factory UserRide.fromJson(Map<String, dynamic> json) {
    // Handle null participants safely
    var participantsList = json['participants'] as List<dynamic>? ?? [];

    return UserRide(
      id: json['id'] as String,
      creatorUid: json['creator_uid'] as String,
      seats: json['seats'] as int,
      scheduledAt: DateTime.parse(json['scheduled_at']),
      pickupPointId: json['pickup_point_id'] as String?,
      pickupName: json['pickup_name'] as String,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      destPointId: json['dest_point_id'] as String?,
      destName: json['dest_name'] as String,
      destLat: (json['dest_lat'] as num).toDouble(),
      destLng: (json['dest_lng'] as num).toDouble(),
      referralCode: json['referral_code'] as String,
      codeExpiresAt: DateTime.parse(json['code_expires_at']),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participantsCount: participantsList.length,
    );
  }
}

class RidesController extends ChangeNotifier {
  bool _isDisposed = false;

  final String _backendBaseUrl = 'http://192.168.78.23:8080';

  final ValueNotifier<List<UserRide>> _userRides =
      ValueNotifier<List<UserRide>>([]);
  ValueNotifier<List<UserRide>> get userRides => _userRides;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  final ValueNotifier<String?> _dataError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get dataError => _dataError;

  // Add error type for better fallback handling
  final ValueNotifier<String?> _errorType = ValueNotifier<String?>(null);
  ValueNotifier<String?> get errorType => _errorType;

  Timer? _refreshTimer;

  RidesController();

  // Retry function for fallback screen
  Future<void> retryFetchUserRides() async {
    _dataError.value = null;
    _errorType.value = null;
    await fetchUserRides();
  }

  // Initialize and fetch user rides
  Future<void> initialize() async {
    // Use addPostFrameCallback to ensure this runs after the current build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchUserRides();
      _startPeriodicRefresh();
    });
  }

  // Fetch all rides created by the current user
  Future<void> fetchUserRides() async {
    if (_isDisposed) return;

    _isLoading.value = true;
    _dataError.value = null;
    _errorType.value = null;
    _safeNotifyListeners();

    try {
      final String? authToken = await FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (authToken == null) {
        _dataError.value = "User not authenticated. Please log in.";
        _errorType.value = "auth";
        _isLoading.value = false;
        _safeNotifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$_backendBaseUrl/rides/user'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _userRides.value = responseData
            .map((rideJson) => UserRide.fromJson(rideJson))
            .toList();
        _dataError.value = null;
        _errorType.value = null;
      } else if (response.statusCode == 404) {
        _userRides.value = [];
        _dataError.value = null;
        _errorType.value = null;
      } else if (response.statusCode == 401) {
        _dataError.value = "Authentication failed. Please log in again.";
        _errorType.value = "auth";
      } else if (response.statusCode >= 500) {
        _dataError.value = "Server error. Please try again later.";
        _errorType.value = "server";
      } else {
        _dataError.value = "Failed to load rides. Please try again.";
        _errorType.value = "unknown";
      }
    } catch (e) {
      if (_isDisposed) return;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('HandshakeException')) {
        _dataError.value =
            "Network connection failed. Please check your internet connection.";
        _errorType.value = "network";
      } else {
        _dataError.value = "Network error loading rides.";
        _errorType.value = "network";
      }
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      _safeNotifyListeners();
    }
  }

  // Safe method to call notifyListeners only when appropriate
  void _safeNotifyListeners() {
    if (!_isDisposed &&
        WidgetsBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks) {
      notifyListeners();
    } else if (!_isDisposed) {
      // Schedule the notification for after the current build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    }
  }

  // Get rides by status
  List<UserRide> getRidesByStatus(String status) {
    return _userRides.value
        .where((ride) => ride.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  // Get upcoming rides (scheduled in the future)
  List<UserRide> getUpcomingRides() {
    final now = DateTime.now();
    return _userRides.value
        .where((ride) => ride.scheduledAt.isAfter(now))
        .toList();
  }

  // Get past rides (scheduled in the past)
  List<UserRide> getPastRides() {
    final now = DateTime.now();
    return _userRides.value
        .where((ride) => ride.scheduledAt.isBefore(now))
        .toList();
  }

  // Start periodic refresh of user rides
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (!_isDisposed) {
        fetchUserRides();
      }
    });
  }

  // Stop periodic refresh
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
  }

  // Refresh rides manually
  Future<void> refreshRides() async {
    await fetchUserRides();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopPeriodicRefresh();
    _userRides.dispose();
    _isLoading.dispose();
    _dataError.dispose();
    super.dispose();
  }
}
