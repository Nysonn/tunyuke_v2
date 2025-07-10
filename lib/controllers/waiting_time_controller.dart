import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class Participant {
  final String id;
  final String rideId;
  final String userUid;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  Participant({
    required this.id,
    required this.rideId,
    required this.userUid,
    this.confirmedAt,
    required this.createdAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      userUid: json['user_uid'] as String,
      confirmedAt: json['confirmed_at'] != null 
          ? DateTime.parse(json['confirmed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RideDetails {
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
  final List<Participant> participants;

  RideDetails({
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
    required this.participants,
  });

  factory RideDetails.fromJson(Map<String, dynamic> json) {
    var participantsList = json['participants'] as List<dynamic>? ?? [];
    List<Participant> participants = participantsList
        .map((p) => Participant.fromJson(p as Map<String, dynamic>))
        .toList();

    return RideDetails(
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
      participants: participants,
    );
  }
}

class WaitingTimeController extends ChangeNotifier {
  bool _isDisposed = false;

  final String _backendBaseUrl = 'http://192.168.241.24:8080';

  final ValueNotifier<RideDetails?> _rideDetails = ValueNotifier<RideDetails?>(null);
  ValueNotifier<RideDetails?> get rideDetails => _rideDetails;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  final ValueNotifier<String?> _dataError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get dataError => _dataError;

  Timer? _refreshTimer;

  WaitingTimeController();

  // Initialize the controller with a ride ID
  Future<void> initialize(String rideId) async {
    await fetchRideDetails(rideId);
    _startPeriodicRefresh(rideId);
  }

  // Fetch ride details from backend
  Future<void> fetchRideDetails(String rideId) async {
    if (_isDisposed) return;
    
    _isLoading.value = true;
    _dataError.value = null;
    notifyListeners();

    try {
      final String? authToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (authToken == null) {
        _dataError.value = "User not authenticated. Please log in.";
        _isLoading.value = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$_backendBaseUrl/rides/$rideId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _rideDetails.value = RideDetails.fromJson(responseData);
        _dataError.value = null;
        print("Ride details fetched successfully");
      } else {
        _dataError.value = "Failed to load ride details: ${response.statusCode} - ${response.body}";
        print("Backend error fetching ride details: ${response.body}");
      }
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = "Network error fetching ride details: $e";
      print("Network error fetching ride details: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  // Confirm participation in the ride
  Future<void> confirmParticipation(String rideId) async {
    if (_isDisposed) return;
    
    _isLoading.value = true;
    _dataError.value = null;
    notifyListeners();

    try {
      final String? authToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (authToken == null) {
        _dataError.value = "User not authenticated. Please log in.";
        _isLoading.value = false;
        notifyListeners();
        return;
      }

      final response = await http.post(
        Uri.parse('$_backendBaseUrl/rides/confirm'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'ride_id': rideId}),
      );

      if (_isDisposed) return;

      if (response.statusCode == 204) {
        // Success - refresh ride details to get updated status
        await fetchRideDetails(rideId);
        _dataError.value = null;
        print("Participation confirmed successfully");
      } else {
        _dataError.value = "Failed to confirm participation: ${response.statusCode} - ${response.body}";
        print("Backend error confirming participation: ${response.body}");
      }
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = "Network error confirming participation: $e";
      print("Network error confirming participation: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  // Get confirmed participants count
  int get confirmedParticipantsCount {
    if (_rideDetails.value == null) return 0;
    return _rideDetails.value!.participants
        .where((p) => p.confirmedAt != null)
        .length;
  }

  // Check if current user has confirmed
  bool get currentUserConfirmed {
    if (_rideDetails.value == null) return false;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    return _rideDetails.value!.participants
        .any((p) => p.userUid == currentUser.uid && p.confirmedAt != null);
  }

  // Start periodic refresh of ride details
  void _startPeriodicRefresh(String rideId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (!_isDisposed) {
        fetchRideDetails(rideId);
      }
    });
  }

  // Stop periodic refresh
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopPeriodicRefresh();
    _rideDetails.dispose();
    _isLoading.dispose();
    _dataError.dispose();
    super.dispose();
  }
}