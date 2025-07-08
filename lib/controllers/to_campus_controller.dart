import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ToCampusController extends ChangeNotifier {
  bool _isDisposed = false;

  final ValueNotifier<List<String>> _pickupStations =
      ValueNotifier<List<String>>([]);
  ValueNotifier<List<String>> get pickupStations => _pickupStations;

  final ValueNotifier<List<String>> _rideTimes = ValueNotifier<List<String>>(
    [],
  );
  ValueNotifier<List<String>> get rideTimes => _rideTimes;

  final ValueNotifier<Map<String, int>> _prices =
      ValueNotifier<Map<String, int>>({});
  ValueNotifier<Map<String, int>> get prices => _prices;

  // New ValueNotifier for morning ready times (map: station -> time)
  final ValueNotifier<Map<String, String>> _morningReadyTimes =
      ValueNotifier<Map<String, String>>({});
  ValueNotifier<Map<String, String>> get morningReadyTimes =>
      _morningReadyTimes;

  // New ValueNotifier for evening ready time (single string)
  final ValueNotifier<String> _eveningReadyTime = ValueNotifier<String>(
    "6:00 pm",
  ); // Default value
  ValueNotifier<String> get eveningReadyTime => _eveningReadyTime;

  final ValueNotifier<String?> _dataError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get dataError => _dataError;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  ToCampusController() {
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (_isDisposed) return;

    _isLoading.value = true;
    _dataError.value = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchPickupStations(),
        _fetchRideTimes(),
        _fetchPrices(),
        _fetchReadyTimes(), // Call the new fetch method
      ]);
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = "Failed to load data: $e";
      print("Error in ToCampusController initial data fetch: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPickupStations() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pickup_points')
          .get();
      if (_isDisposed) return;

      List<String> fetchedStations = [];
      for (var doc in snapshot.docs) {
        if (doc.data() != null &&
            (doc.data() as Map<String, dynamic>).containsKey('name')) {
          fetchedStations.add(
            (doc.data() as Map<String, dynamic>)['name'] as String,
          );
        }
      }
      _pickupStations.value = fetchedStations;
      print("Fetched pickup stations: ${_pickupStations.value}");
    } catch (e) {
      if (_isDisposed) return;
      throw Exception("Error fetching pickup stations: $e");
    }
  }

  Future<void> _fetchRideTimes() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ride_times')
          .orderBy('time')
          .get(); // Order for consistent display
      if (_isDisposed) return;

      List<String> fetchedTimes = [];
      for (var doc in snapshot.docs) {
        if (doc.data() != null &&
            (doc.data() as Map<String, dynamic>).containsKey('time')) {
          fetchedTimes.add(
            (doc.data() as Map<String, dynamic>)['time'] as String,
          );
        }
      }
      _rideTimes.value = fetchedTimes;
      print("Fetched ride times: ${_rideTimes.value}");
    } catch (e) {
      if (_isDisposed) return;
      throw Exception("Error fetching ride times: $e");
    }
  }

  Future<void> _fetchPrices() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('prices')
          .get();
      if (_isDisposed) return;

      Map<String, int> fetchedPrices = {};
      for (var doc in snapshot.docs) {
        if (doc.data() != null &&
            (doc.data() as Map<String, dynamic>).containsKey('fare')) {
          // Ensure 'fare' is treated as an int, handle potential double from Firestore
          final fareValue = (doc.data() as Map<String, dynamic>)['fare'];
          if (fareValue is int) {
            fetchedPrices[doc.id] = fareValue;
          } else if (fareValue is double) {
            fetchedPrices[doc.id] = fareValue.toInt();
          } else {
            print(
              "Warning: Fare for ${doc.id} is not an int or double: $fareValue",
            );
            fetchedPrices[doc.id] = 0; // Default to 0 or handle error
          }
        }
      }
      _prices.value = fetchedPrices;
      print("Fetched prices: ${_prices.value}");
    } catch (e) {
      if (_isDisposed) return;
      throw Exception("Error fetching prices: $e");
    }
  }

  Future<void> _fetchReadyTimes() async {
    try {
      DocumentSnapshot morningDoc = await FirebaseFirestore.instance
          .collection('ready_times')
          .doc('morning')
          .get();
      DocumentSnapshot eveningDoc = await FirebaseFirestore.instance
          .collection('ready_times')
          .doc('evening')
          .get();

      if (_isDisposed) return;

      if (morningDoc.exists && morningDoc.data() != null) {
        // Cast to Map<String, dynamic> and then to Map<String, String>
        final data = morningDoc.data() as Map<String, dynamic>;
        _morningReadyTimes.value = data.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        print("Fetched morning ready times: ${_morningReadyTimes.value}");
      } else {
        print("Morning ready times document not found in Firestore.");
        _morningReadyTimes.value = {}; // Set to empty map if not found
      }

      if (eveningDoc.exists &&
          eveningDoc.data() != null &&
          (eveningDoc.data() as Map<String, dynamic>).containsKey('time')) {
        _eveningReadyTime.value =
            (eveningDoc.data() as Map<String, dynamic>)['time'] as String;
        print("Fetched evening ready time: ${_eveningReadyTime.value}");
      } else {
        print(
          "Evening ready time document not found in Firestore or 'time' field missing.",
        );
        _eveningReadyTime.value = "6:00 pm"; // Default value
      }
    } catch (e) {
      if (_isDisposed) return;
      throw Exception("Error fetching ready times: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pickupStations.dispose();
    _rideTimes.dispose();
    _prices.dispose();
    _morningReadyTimes.dispose(); // Dispose new ValueNotifiers
    _eveningReadyTime.dispose(); // Dispose new ValueNotifiers
    _dataError.dispose();
    _isLoading.dispose();
    super.dispose();
  }
}
