import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingController extends ChangeNotifier {
  bool _isDisposed = false;

  final String _backendBaseUrl = 'https://tunyuke-backend-api.onrender.com';

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  final ValueNotifier<String?> _dataError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get dataError => _dataError;

  final ValueNotifier<String?> _referralCode = ValueNotifier<String?>(null);
  ValueNotifier<String?> get referralCode => _referralCode;

  final ValueNotifier<String?> _joinedRideId = ValueNotifier<String?>(null);
  ValueNotifier<String?> get joinedRideId => _joinedRideId;

  // Add error type for better fallback handling
  final ValueNotifier<String?> _errorType = ValueNotifier<String?>(null);
  ValueNotifier<String?> get errorType => _errorType;

  OnboardingController();

  // Set referral code
  void setReferralCode(String? code) {
    if (_isDisposed) return;
    _referralCode.value = code?.toUpperCase();
    _dataError.value = null;
    _errorType.value = null;
    notifyListeners();
  }

  // Clear data
  void clearData() {
    if (_isDisposed) return;
    _referralCode.value = null;
    _joinedRideId.value = null;
    _dataError.value = null;
    _errorType.value = null;
    _isLoading.value = false;
    notifyListeners();
  }

  // Retry function for fallback screen
  Future<void> retryJoinRide() async {
    _dataError.value = null;
    _errorType.value = null;
    await joinRideWithCode();
  }

  // Join ride using referral code
  Future<void> joinRideWithCode() async {
    if (_isDisposed) return;

    if (_referralCode.value == null || _referralCode.value!.trim().isEmpty) {
      _dataError.value = "Please enter a referral code";
      _errorType.value = "validation";
      notifyListeners();
      return;
    }

    _isLoading.value = true;
    _dataError.value = null;
    _errorType.value = null;
    notifyListeners();

    try {
      final String? authToken = await FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (authToken == null) {
        _dataError.value = "User not authenticated. Please log in.";
        _errorType.value = "auth";
        _isLoading.value = false;
        notifyListeners();
        return;
      }

      // Step 1: Join the ride
      final joinResponse = await http.post(
        Uri.parse('$_backendBaseUrl/rides/join'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'referral_code': _referralCode.value}),
      );

      if (_isDisposed) return;

      if (joinResponse.statusCode == 201) {
        // Step 2: Fetch the ride ID using the referral code
        await _fetchRideByReferralCode(_referralCode.value!, authToken);
      } else if (joinResponse.statusCode == 400) {
        try {
          final errorData = json.decode(joinResponse.body);
          final errorBody = errorData['error'] as String;
          if (errorBody.contains("already a participant")) {
            await _fetchRideByReferralCode(_referralCode.value!, authToken);
          } else {
            _dataError.value = errorBody;
            _errorType.value = "client";
          }
        } catch (e) {
          _dataError.value = "Unable to join ride. Please try again.";
          _errorType.value = "client";
        }
      } else if (joinResponse.statusCode == 403) {
        _dataError.value =
            "Access denied. You may not have permission to join this ride.";
        _errorType.value = "auth";
      } else if (joinResponse.statusCode == 401) {
        _dataError.value =
            "Authentication failed. Please log out and log back in.";
        _errorType.value = "auth";
      } else if (joinResponse.statusCode >= 500) {
        _dataError.value = "Server error. Please try again later.";
        _errorType.value = "server";
      } else {
        _dataError.value = "Failed to join ride. Please try again.";
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
        _dataError.value =
            "Network error. Please check your connection and try again.";
        _errorType.value = "network";
      }
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  // Fetch ride details by referral code using the new endpoint
  Future<void> _fetchRideByReferralCode(
    String referralCode,
    String authToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/rides/referral/$referralCode'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _joinedRideId.value = responseData['id'] as String;
        print("Successfully fetched ride ID: ${_joinedRideId.value}");
      } else if (response.statusCode == 404) {
        _dataError.value = "Ride not found for this referral code.";
        print("Ride not found for referral code: ${response.body}");
      } else {
        _dataError.value =
            "Failed to fetch ride details: ${response.statusCode}";
        print("Backend error fetching ride by referral code: ${response.body}");
      }
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = "Network error fetching ride details: $e";
      print("Error fetching ride by referral code: $e");
    }
  }

  // Validate referral code format (basic validation)
  String? validateReferralCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return "Please enter a referral code";
    }

    if (code.trim().length < 3) {
      return "Referral code is too short";
    }

    if (code.trim().length > 20) {
      return "Referral code is too long";
    }

    // Basic alphanumeric check
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code.trim().toUpperCase())) {
      return "Referral code should contain only letters and numbers";
    }

    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isLoading.dispose();
    _dataError.dispose();
    _referralCode.dispose();
    _joinedRideId.dispose();
    _errorType.dispose();
    super.dispose();
  }
}
