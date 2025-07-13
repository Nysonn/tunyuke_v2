import 'package:flutter/material.dart';
import 'package:Tunyuke/services/api_service.dart';

class RidesController extends ChangeNotifier {
  bool _isDisposed = false;

  // Campus rides (To Campus)
  final ValueNotifier<List<Map<String, dynamic>>> _campusRides =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  ValueNotifier<List<Map<String, dynamic>>> get campusRides => _campusRides;

  // From Campus rides
  final ValueNotifier<List<Map<String, dynamic>>> _fromCampusRides =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  ValueNotifier<List<Map<String, dynamic>>> get fromCampusRides =>
      _fromCampusRides;

  // Scheduled team rides
  final ValueNotifier<List<Map<String, dynamic>>> _scheduledRides =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  ValueNotifier<List<Map<String, dynamic>>> get scheduledRides =>
      _scheduledRides;

  // Loading and error states
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  final ValueNotifier<String?> _error = ValueNotifier<String?>(null);
  ValueNotifier<String?> get error => _error;

  // Refresh indicator
  final ValueNotifier<bool> _isRefreshing = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isRefreshing => _isRefreshing;

  // Add a flag to track if we have any data at all
  final ValueNotifier<bool> _hasData = ValueNotifier<bool>(false);
  ValueNotifier<bool> get hasData => _hasData;

  RidesController() {
    fetchAllRides();
  }

  Future<void> fetchAllRides() async {
    if (_isDisposed) return;

    _isLoading.value = true;
    _error.value = null;
    notifyListeners();

    try {
      // Fetch all rides concurrently
      final results = await Future.wait([
        _fetchCampusRides(),
        _fetchFromCampusRides(),
        _fetchScheduledRides(),
      ]);

      // Check if we have any data at all
      _updateHasDataFlag();

      // If no data and no errors, show appropriate message
      if (!_hasData.value && _error.value == null) {
        _error.value = "no_rides"; // Special error code for no rides
      }
    } catch (e) {
      if (_isDisposed) return;
      _error.value = "Failed to load rides: $e";
      print("Error in RidesController: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> refreshRides() async {
    if (_isDisposed) return;

    _isRefreshing.value = true;
    _error.value = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchCampusRides(),
        _fetchFromCampusRides(),
        _fetchScheduledRides(),
      ]);

      _updateHasDataFlag();

      // If no data and no errors, show appropriate message
      if (!_hasData.value && _error.value == null) {
        _error.value = "no_rides";
      }
    } catch (e) {
      if (_isDisposed) return;
      _error.value = "Failed to refresh rides: $e";
      print("Error refreshing rides: $e");
    } finally {
      if (_isDisposed) return;
      _isRefreshing.value = false;
      notifyListeners();
    }
  }

  void _updateHasDataFlag() {
    _hasData.value =
        _campusRides.value.isNotEmpty ||
        _fromCampusRides.value.isNotEmpty ||
        _scheduledRides.value.isNotEmpty;
  }

  Future<void> _fetchCampusRides() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final rides = await ApiService.getUserCampusRides();
        if (_isDisposed) return;
        _campusRides.value = rides ?? []; // Ensure non-null
        print("Fetched ${_campusRides.value.length} campus rides");
        return; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          if (_isDisposed) return;
          print("Error fetching campus rides after $maxRetries attempts: $e");
          _campusRides.value = []; // Set empty list on final failure
          return;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: retryCount * 2));
        print("Retrying campus rides fetch, attempt $retryCount");
      }
    }
  }

  Future<void> _fetchFromCampusRides() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final rides = await ApiService.getUserFromCampusRides();
        if (_isDisposed) return;
        _fromCampusRides.value = rides ?? [];
        print("Fetched ${_fromCampusRides.value.length} from campus rides");
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          if (_isDisposed) return;
          print(
            "Error fetching from campus rides after $maxRetries attempts: $e",
          );
          _fromCampusRides.value = [];
          return;
        }

        await Future.delayed(Duration(seconds: retryCount * 2));
        print("Retrying from campus rides fetch, attempt $retryCount");
      }
    }
  }

  Future<void> _fetchScheduledRides() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final rides = await ApiService.getUserScheduledRides();
        if (_isDisposed) return;
        _scheduledRides.value = rides ?? [];
        print("Fetched ${_scheduledRides.value.length} scheduled rides");
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          if (_isDisposed) return;
          print(
            "Error fetching scheduled rides after $maxRetries attempts: $e",
          );
          _scheduledRides.value = [];
          return;
        }

        await Future.delayed(Duration(seconds: retryCount * 2));
        print("Retrying scheduled rides fetch, attempt $retryCount");
      }
    }
  }

  // Get total number of rides
  int get totalRidesCount {
    return _campusRides.value.length +
        _fromCampusRides.value.length +
        _scheduledRides.value.length;
  }

  // Get user-friendly error message
  String get userFriendlyError {
    if (_error.value == null) return "";

    if (_error.value == "no_rides") {
      return "You have not booked any rides";
    }

    if (_error.value!.contains("Network error") ||
        _error.value!.contains("Failed to refresh") ||
        _error.value!.contains("Failed to load")) {
      return "Failed to refresh rides. Please check your internet connection and try again.";
    }

    return "Something went wrong. Please try again.";
  }

  // Check if error is just "no rides" (not a real error)
  bool get isNoRidesError => _error.value == "no_rides";

  // Get ride status color
  Color getRideStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get ride status icon
  IconData getRideStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _campusRides.dispose();
    _fromCampusRides.dispose();
    _scheduledRides.dispose();
    _isLoading.dispose();
    _error.dispose();
    _isRefreshing.dispose();
    _hasData.dispose();
    super.dispose();
  }
}
