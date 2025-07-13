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

  RidesController() {
    fetchAllRides();
  }

  Future<void> fetchAllRides() async {
    if (_isDisposed) return;

    _isLoading.value = true;
    _error.value = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchCampusRides(),
        _fetchFromCampusRides(),
        _fetchScheduledRides(),
      ]);
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

  Future<void> _fetchCampusRides() async {
    try {
      final rides = await ApiService.getUserCampusRides();
      if (_isDisposed) return;
      _campusRides.value = rides;
      print("Fetched ${rides.length} campus rides");
    } catch (e) {
      if (_isDisposed) return;
      print("Error fetching campus rides: $e");
      throw e;
    }
  }

  Future<void> _fetchFromCampusRides() async {
    try {
      final rides = await ApiService.getUserFromCampusRides();
      if (_isDisposed) return;
      _fromCampusRides.value = rides;
      print("Fetched ${rides.length} from campus rides");
    } catch (e) {
      if (_isDisposed) return;
      print("Error fetching from campus rides: $e");
      throw e;
    }
  }

  Future<void> _fetchScheduledRides() async {
    try {
      final rides = await ApiService.getUserScheduledRides();
      if (_isDisposed) return;
      _scheduledRides.value = rides;
      print("Fetched ${rides.length} scheduled rides");
    } catch (e) {
      if (_isDisposed) return;
      print("Error fetching scheduled rides: $e");
      throw e;
    }
  }

  // Get total number of rides
  int get totalRidesCount {
    return _campusRides.value.length +
        _fromCampusRides.value.length +
        _scheduledRides.value.length;
  }

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
    super.dispose();
  }
}
