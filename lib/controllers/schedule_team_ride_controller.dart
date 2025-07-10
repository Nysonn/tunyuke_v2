import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Access the key from .env
final GoogleMapsPlaces _places = GoogleMapsPlaces(
  apiKey: dotenv.env['Maps_API_KEY']!,
);

// Define a structure for your backend's pickup/destination points
class TunyukeLocationPoint {
  final String? id; // Can be null if custom destination
  final String name;
  final double lat;
  final double lng;

  TunyukeLocationPoint({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory TunyukeLocationPoint.fromJson(Map<String, dynamic> json) {
    return TunyukeLocationPoint(
      id: json['id'] as String?,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'lat': lat, 'lng': lng};
  }
}

class ScheduleTeamRideController extends ChangeNotifier {
  bool _isDisposed = false;

  // Use 10.0.2.2 for Android emulator, or your actual IP for physical devices
  final String _backendBaseUrl =
      'http://192.168.241.24:8080'; // Your Go backend URL

  final ValueNotifier<int?> _numberOfTravelers = ValueNotifier<int?>(null);
  ValueNotifier<int?> get numberOfTravelers => _numberOfTravelers;

  // Pickup selection: "current_location" or "pickup_station"
  final ValueNotifier<String?> _selectedPickupOption = ValueNotifier<String?>(
    "pickup_station",
  ); // Default to pickup station
  ValueNotifier<String?> get selectedPickupOption => _selectedPickupOption;

  // Destination selection: "pickup_station" or "custom_destination"
  final ValueNotifier<String?> _selectedDestinationOption =
      ValueNotifier<String?>("pickup_station"); // Default to pickup station
  ValueNotifier<String?> get selectedDestinationOption =>
      _selectedDestinationOption;

  // List of pre-defined pickup stations from backend
  final ValueNotifier<List<TunyukeLocationPoint>> _tunyukeStations =
      ValueNotifier<List<TunyukeLocationPoint>>([]);
  ValueNotifier<List<TunyukeLocationPoint>> get tunyukeStations =>
      _tunyukeStations;

  // Selected pre-defined pickup station
  final ValueNotifier<TunyukeLocationPoint?> _selectedPickupStation =
      ValueNotifier<TunyukeLocationPoint?>(null);
  ValueNotifier<TunyukeLocationPoint?> get selectedPickupStation =>
      _selectedPickupStation;

  // Selected pre-defined destination station
  final ValueNotifier<TunyukeLocationPoint?> _selectedDestinationStation =
      ValueNotifier<TunyukeLocationPoint?>(null);
  ValueNotifier<TunyukeLocationPoint?> get selectedDestinationStation =>
      _selectedDestinationStation;

  // For custom destination text input and selected Google Place
  final ValueNotifier<String?> _customDestinationQuery = ValueNotifier<String?>(
    null,
  );
  ValueNotifier<String?> get customDestinationQuery => _customDestinationQuery;

  final ValueNotifier<PlacesSearchResult?> _selectedCustomDestination =
      ValueNotifier<PlacesSearchResult?>(null);
  ValueNotifier<PlacesSearchResult?> get selectedCustomDestination =>
      _selectedCustomDestination;

  // Current user's location coordinates for "Current Location" pickup option
  final ValueNotifier<Position?> _currentLocation = ValueNotifier<Position?>(
    null,
  );
  ValueNotifier<Position?> get currentLocation => _currentLocation;

  final ValueNotifier<DateTime?> _desiredDateTime = ValueNotifier<DateTime?>(
    null,
  );
  ValueNotifier<DateTime?> get desiredDateTime => _desiredDateTime;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  final ValueNotifier<String?> _dataError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get dataError => _dataError;

  // Properties for backend response
  final ValueNotifier<String?> _referralCode = ValueNotifier<String?>(null);
  ValueNotifier<String?> get referralCode => _referralCode;

  final ValueNotifier<String?> _rideId = ValueNotifier<String?>(null); // Add this
  ValueNotifier<String?> get rideId => _rideId; // Add this

  final ValueNotifier<int?> _farePerPerson = ValueNotifier<int?>(
    null,
  ); // Backend will calculate this
  ValueNotifier<int?> get farePerPerson => _farePerPerson;

  // Constructor
  ScheduleTeamRideController() {
    _fetchTunyukeStations(); // Fetch initial pickup/destination stations from backend
  }

  // Initialize or re-initialize the controller (for retry functionality)
  Future<void> initialize() async {
    await _fetchTunyukeStations();
  }

  // --- Setters for UI components ---
  void setNumberOfTravelers(int? count) {
    if (_isDisposed) return;
    _numberOfTravelers.value = count;
    notifyListeners();
  }

  void setSelectedPickupOption(String? option) {
    if (_isDisposed) return;
    _selectedPickupOption.value = option;
    if (option == "current_location") {
      _selectedPickupStation.value = null; // Clear pre-selected station
      _getCurrentLocation(); // Attempt to get current location
    } else {
      _currentLocation.value = null; // Clear current location
    }
    notifyListeners();
  }

  void setSelectedPickupStation(TunyukeLocationPoint? station) {
    if (_isDisposed) return;
    _selectedPickupStation.value = station;
    if (station != null) {
      _selectedPickupOption.value = "pickup_station";
      _currentLocation.value = null; // Clear current location
    }
    notifyListeners();
  }

  void setSelectedDestinationOption(String? option) {
    if (_isDisposed) return;
    _selectedDestinationOption.value = option;
    if (option == "custom_destination") {
      _selectedDestinationStation.value = null; // Clear pre-selected station
    } else {
      // It's "pickup_station"
      _selectedCustomDestination.value = null;
      _customDestinationQuery.value = null;
    }
    notifyListeners();
  }

  void setSelectedDestinationStation(TunyukeLocationPoint? station) {
    if (_isDisposed) return;
    _selectedDestinationStation.value = station;
    if (station != null) {
      _selectedDestinationOption.value = "pickup_station";
      _selectedCustomDestination.value = null;
      _customDestinationQuery.value = null;
    }
    notifyListeners();
  }

  void setCustomDestinationQuery(String? query) {
    if (_isDisposed) return;
    _customDestinationQuery.value = query;
    // Reset selected custom destination if query changes and it's not the exact selected place
    if (query == null ||
        query.isEmpty ||
        _selectedCustomDestination.value?.name != query) {
      _selectedCustomDestination.value = null;
    }
    notifyListeners();
  }

  void setSelectedCustomDestination(PlacesSearchResult? result) {
    if (_isDisposed) return;
    _selectedCustomDestination.value = result;
    if (result != null) {
      _selectedDestinationOption.value = "custom_destination";
      _customDestinationQuery.value =
          result.name; // Keep the displayed text consistent
      _selectedDestinationStation.value = null; // Clear pre-selected station
    }
    notifyListeners();
  }

  void setDesiredDateTime(DateTime? dateTime) {
    if (_isDisposed) return;
    _desiredDateTime.value = dateTime;
    notifyListeners();
  }

  // --- Data Fetching from Backend (Pickup Points) ---
  Future<void> _fetchTunyukeStations() async {
    if (_isDisposed) return;
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

      final response = await http.get(
        Uri.parse('$_backendBaseUrl/pickup_points'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        _tunyukeStations.value = jsonList
            .map((json) => TunyukeLocationPoint.fromJson(json))
            .toList();
        print(
          "Fetched Tunyuke stations: ${_tunyukeStations.value.map((e) => e.name).toList()}",
        );

        // Optionally set a default selected pickup/destination station if list is not empty
        if (_tunyukeStations.value.isNotEmpty) {
          if (_selectedPickupStation.value == null) {
            _selectedPickupStation.value = _tunyukeStations.value.first;
            _selectedPickupOption.value = "pickup_station";
          }
          if (_selectedDestinationStation.value == null) {
            _selectedDestinationStation.value = _tunyukeStations.value.first;
            _selectedDestinationOption.value = "pickup_station";
          }
        }
      } else {
        _dataError.value =
            "Failed to load pickup points: ${response.statusCode} - ${response.body}";
        print("Backend error fetching pickup points: ${response.body}");
      }
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = "Network error fetching pickup points: $e";
      print("Network error fetching pickup points: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  // --- Location related methods ---
  Future<void> _getCurrentLocation() async {
    if (_isDisposed) return;
    _isLoading.value = true;
    _dataError.value = null;
    notifyListeners();

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _dataError.value = 'Location services are disabled.';
      _isLoading.value = false;
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _dataError.value = 'Location permissions are denied';
        _isLoading.value = false;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _dataError.value =
          'Location permissions are permanently denied, we cannot request permissions.';
      _isLoading.value = false;
      notifyListeners();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (_isDisposed) return;
      _currentLocation.value = position;
      print("Current Location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = 'Error getting current location: $e';
      print("Error getting current location: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  // Google Places Autocomplete Search
  Future<List<PlacesSearchResult>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    try {
      PlacesAutocompleteResponse response = await _places.autocomplete(
        query,
        language: "en",
        components: [
          Component(Component.country, "ug"),
        ], // Restrict to Uganda (Mbarara is in Uganda)
        strictbounds: false,
        types: ["geocode", "establishment"],
      );

      if (response.status == 'OK') {
        return response.predictions
            .map(
              (p) => PlacesSearchResult(
                placeId: p.placeId,
                name:
                    p.description ??
                    p.structuredFormatting?.mainText ??
                    p.reference ??
                    query,
                geometry:
                    null, // Geometry will be fetched with place details if needed
              ),
            )
            .toList();
      } else {
        print("Places API error: ${response.errorMessage}");
        return [];
      }
    } catch (e) {
      print("Error searching places: $e");
      return [];
    }
  }

  // Fetch Place Details (for LatLng)
  Future<PlacesDetailsResponse?> getPlaceDetails(String placeId) async {
    try {
      PlacesDetailsResponse response = await _places.getDetailsByPlaceId(
        placeId,
      );
      if (response.status == 'OK') {
        return response;
      } else {
        print("Places Details API error: ${response.errorMessage}");
        return null;
      }
    } catch (e) {
      print("Error fetching place details: $e");
      return null;
    }
  }

  // --- Backend API Interaction (Schedule Ride) ---
  Future<void> scheduleTeamRide() async {
    if (_isDisposed) return;
    _isLoading.value = true;
    _dataError.value = null;
    _referralCode.value = null;
    _farePerPerson.value = null;
    notifyListeners();

    // 1. Get Firebase ID Token
    final String? authToken = await FirebaseAuth.instance.currentUser
        ?.getIdToken();
    if (authToken == null) {
      _dataError.value =
          "User not authenticated. Please log in to schedule a ride.";
      _isLoading.value = false;
      notifyListeners();
      return;
    }

    // 2. Validate basic inputs
    if (_numberOfTravelers.value == null ||
        _numberOfTravelers.value! < 2 ||
        _numberOfTravelers.value! > 60) {
      _dataError.value = "Number of travelers must be between 2 and 60.";
      _isLoading.value = false;
      notifyListeners();
      return;
    }
    if (_desiredDateTime.value == null ||
        _desiredDateTime.value!.isBefore(DateTime.now())) {
      _dataError.value = "Please select a future date and time.";
      _isLoading.value = false;
      notifyListeners();
      return;
    }

    // 3. Determine Pickup Location Data
    String? pickupPointId;
    String pickupName;
    double pickupLat;
    double pickupLng;

    if (_selectedPickupOption.value == "current_location") {
      if (_currentLocation.value == null) {
        _dataError.value =
            "Failed to get current location. Please try again or select a pickup station.";
        _isLoading.value = false;
        notifyListeners();
        return;
      }
      // For current location, we don't have a fixed point_id from the backend.
      // The backend might identify the user's current location dynamically.
      // For now, we'll use a placeholder ID or leave it null if the backend allows.
      // Assuming your backend can handle a null/empty pickup_point_id for current location,
      // and uses the lat/lng. If it *requires* an ID, you might need a "dynamic" ID
      // or to have the backend resolve the closest pickup point.
      pickupPointId = null; // Backend handles dynamic current location
      pickupName = "Current Location"; // Descriptive name for the user
      pickupLat = _currentLocation.value!.latitude;
      pickupLng = _currentLocation.value!.longitude;
    } else if (_selectedPickupOption.value == "pickup_station") {
      if (_selectedPickupStation.value == null) {
        _dataError.value = "Please select a pickup station.";
        _isLoading.value = false;
        notifyListeners();
        return;
      }
      pickupPointId = _selectedPickupStation.value!.id;
      pickupName = _selectedPickupStation.value!.name;
      pickupLat = _selectedPickupStation.value!.lat;
      pickupLng = _selectedPickupStation.value!.lng;
    } else {
      _dataError.value = "Please select a pickup option.";
      _isLoading.value = false;
      notifyListeners();
      return;
    }

    // 4. Determine Destination Location Data
    String? destPointId;
    String destName;
    double destLat;
    double destLng;

    if (_selectedDestinationOption.value == "pickup_station") {
      if (_selectedDestinationStation.value == null) {
        _dataError.value = "Please select a destination station.";
        _isLoading.value = false;
        notifyListeners();
        return;
      }
      destPointId = _selectedDestinationStation.value!.id;
      destName = _selectedDestinationStation.value!.name;
      destLat = _selectedDestinationStation.value!.lat;
      destLng = _selectedDestinationStation.value!.lng;
    } else if (_selectedDestinationOption.value == "custom_destination") {
      if (_selectedCustomDestination.value == null ||
          _selectedCustomDestination.value!.placeId == null) {
        _dataError.value =
            "Please select a valid custom destination from the suggestions.";
        _isLoading.value = false;
        notifyListeners();
        return;
      }
      // Fetch full details for LatLng from Google Places API
      PlacesDetailsResponse? details = await getPlaceDetails(
        _selectedCustomDestination.value!.placeId!,
      );
      if (details == null || details.result.geometry == null) {
        _dataError.value =
            "Could not get full details for the custom destination.";
        _isLoading.value = false;
        notifyListeners();
        return;
      }
      destPointId =
          null; // Custom destinations don't have a pre-defined ID from Tunyuke backend
      destName = _selectedCustomDestination.value!.name;
      destLat = details.result.geometry!.location.lat;
      destLng = details.result.geometry!.location.lng;
    } else {
      _dataError.value = "Please select a destination option.";
      _isLoading.value = false;
      notifyListeners();
      return;
    }

    // 5. Construct the request body for your Golang backend
    Map<String, dynamic> requestBody = {
      "seats": _numberOfTravelers.value,
      "scheduled_at":
          '${_desiredDateTime.value!.toUtc().toIso8601String().split('.')[0]}Z',
      "pickup_point_id": pickupPointId,
      "pickup_name": pickupName,
      "pickup_lat": pickupLat,
      "pickup_lng": pickupLng,
      "dest_point_id": destPointId,
      "dest_name": destName,
      "dest_lat": destLat,
      "dest_lng": destLng,
    };

    print("Sending request body to backend: ${json.encode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/rides'), // Corrected endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // Add Authorization header
        },
        body: json.encode(requestBody),
      );

      if (_isDisposed) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 200 OK or 201 Created
        final Map<String, dynamic> responseData = json.decode(response.body);
        _rideId.value = responseData['id']; // Add this line
        _referralCode.value = responseData['referral_code'];
        // The API response does not explicitly show 'fare_per_person' in the example.
        // You'll need to confirm if your backend calculation returns this.
        // If not, you'd calculate it on the frontend or make another API call.
        // For now, I'll assume the backend will return it or you'll calculate a placeholder.
        // Let's set a dummy fare for now, and note this as an area to integrate with backend.
        _farePerPerson.value =
            (responseData['seats'] != null && responseData['seats'] > 0)
            ? (20000 / responseData['seats'])
                  .ceil() // Placeholder calculation (e.g. 20k UGX total for a ride)
            : 0;

        _dataError.value = null; // Clear any previous errors
        print("Team ride scheduled successfully! Code: ${_referralCode.value}");
      } else {
        _dataError.value =
            "Failed to schedule ride: ${response.statusCode} - ${response.body}";
        print(
          "Backend error scheduling ride: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = "Network error scheduling ride: $e";
      print("Network error scheduling ride: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _numberOfTravelers.dispose();
    _selectedPickupOption.dispose();
    _selectedDestinationOption.dispose();
    _tunyukeStations.dispose();
    _selectedPickupStation.dispose();
    _selectedDestinationStation.dispose();
    _customDestinationQuery.dispose();
    _selectedCustomDestination.dispose();
    _currentLocation.dispose();
    _desiredDateTime.dispose();
    _isLoading.dispose();
    _dataError.dispose();
    _referralCode.dispose();
    _rideId.dispose(); // Add this line
    _farePerPerson.dispose();
    super.dispose();
  }
}

// Simple wrapper for Places Autocomplete results to match PlacesSearchResult structure
class PlacesSearchResult {
  final String? placeId;
  final String name;
  final Location? geometry; // Latitude/Longitude, fetched with details

  PlacesSearchResult({this.placeId, required this.name, this.geometry});
}
