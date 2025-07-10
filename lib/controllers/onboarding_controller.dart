import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingController extends ChangeNotifier {
  bool _isDisposed = false;

  final String _backendBaseUrl = 'http://192.168.241.24:8080';

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  final ValueNotifier<String?> _dataError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get dataError => _dataError;

  final ValueNotifier<String?> _referralCode = ValueNotifier<String?>(null);
  ValueNotifier<String?> get referralCode => _referralCode;

  final ValueNotifier<String?> _joinedRideId = ValueNotifier<String?>(null);
  ValueNotifier<String?> get joinedRideId => _joinedRideId;

  OnboardingController();

  // Set referral code
  void setReferralCode(String? code) {
    if (_isDisposed) return;
    _referralCode.value = code
        ?.toUpperCase(); // Convert to uppercase for consistency
    _dataError.value = null; // Clear any previous errors
    notifyListeners();
  }

  // Join ride using referral code
  Future<void> joinRideWithCode() async {
    if (_isDisposed) return;

    if (_referralCode.value == null || _referralCode.value!.trim().isEmpty) {
      _dataError.value = "Please enter a referral code";
      notifyListeners();
      return;
    }

    _isLoading.value = true;
    _dataError.value = null;
    notifyListeners();

    try {
      final String? authToken = await FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (authToken == null) {
        _dataError.value = "User not authenticated. Please log in.";
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
        body: json.encode({'referral_code': _referralCode.value!.trim()}),
      );

      if (_isDisposed) return;

      if (joinResponse.statusCode == 204) {
        // Success - now fetch ride details using the new endpoint
        await _fetchRideByReferralCode(_referralCode.value!.trim(), authToken);
        _dataError.value = null;
        print("Successfully joined ride with code: ${_referralCode.value}");
      } else if (joinResponse.statusCode == 404) {
        _dataError.value = "Invalid referral code. Please check and try again.";
        print("Invalid referral code: ${joinResponse.body}");
      } else if (joinResponse.statusCode == 400) {
        // Parse error message for more specific feedback
        try {
          final errorBody = joinResponse.body;
          if (errorBody.contains("expired")) {
            _dataError.value = "This referral code has expired.";
          } else if (errorBody.contains("full")) {
            _dataError.value = "This ride is already full.";
          } else {
            _dataError.value = "Unable to join ride: $errorBody";
          }
        } catch (e) {
          _dataError.value = "Unable to join ride. Please try again.";
        }
        print("Backend error joining ride: ${joinResponse.body}");
      } else if (joinResponse.statusCode == 403) {
        // Handle 403 Forbidden error
        _dataError.value =
            "Access denied. You may not have permission to join this ride or you're already a participant.";
        print("403 Forbidden error joining ride: ${joinResponse.body}");
      } else if (joinResponse.statusCode == 401) {
        // Handle 401 Unauthorized error
        _dataError.value =
            "Authentication failed. Please log out and log back in.";
        print("401 Unauthorized error joining ride: ${joinResponse.body}");
      } else {
        _dataError.value =
            "Failed to join ride: ${joinResponse.statusCode} - ${joinResponse.body}";
        print(
          "Backend error joining ride: ${joinResponse.statusCode} - ${joinResponse.body}",
        );
      }
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value =
          "Network error. Please check your connection and try again.";
      print("Network error joining ride: $e");
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

  // Clear all data
  void clearData() {
    if (_isDisposed) return;
    _referralCode.value = null;
    _joinedRideId.value = null;
    _dataError.value = null;
    _isLoading.value = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isLoading.dispose();
    _dataError.dispose();
    _referralCode.dispose();
    _joinedRideId.dispose();
    super.dispose();
  }
}
