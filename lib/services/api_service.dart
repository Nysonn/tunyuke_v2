import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://tunyuke-backend-api.onrender.com';

  static Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> createCampusRide({
    required String pickupStation,
    required String rideTime,
    required int fare,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/campus-rides'),
        headers: headers,
        body: jsonEncode({
          'pickup_station': pickupStation,
          'ride_time': rideTime,
          'fare': fare,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create campus ride: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createFromCampusRide({
    required String destination,
    required String rideTime,
    required int fare,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/from-campus-rides'),
        headers: headers,
        body: jsonEncode({
          'destination': destination,
          'ride_time': rideTime,
          'fare': fare,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create from campus ride: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserCampusRides() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rides/campus'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Handle empty response body
        if (response.body.trim().isEmpty) {
          print('Empty response body for campus rides');
          return [];
        }

        final data = json.decode(response.body);

        // Handle null response
        if (data == null) {
          print('Null data received for campus rides');
          return [];
        }

        // Handle direct list response
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map(
              (item) =>
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
            ),
          );
        }

        // Handle object with rides property
        if (data is Map<String, dynamic>) {
          if (data.containsKey('rides') && data['rides'] is List) {
            return List<Map<String, dynamic>>.from(
              data['rides'].map(
                (item) =>
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
              ),
            );
          }

          // Handle object with data property
          if (data.containsKey('data') && data['data'] is List) {
            return List<Map<String, dynamic>>.from(
              data['data'].map(
                (item) =>
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
              ),
            );
          }
        }

        print('Unexpected data format for campus rides: ${data.runtimeType}');
        return [];
      } else if (response.statusCode == 404) {
        // 404 might mean no rides found, not an error
        print('No campus rides found (404)');
        return [];
      } else {
        throw Exception('Failed to load campus rides: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserCampusRides: $e');
      // Return empty list for network errors too
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFromCampusRides() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/from-campus-rides/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Handle empty response body
        if (response.body.trim().isEmpty) {
          print('Empty response body for from campus rides');
          return [];
        }

        final data = jsonDecode(response.body);

        // Handle null response
        if (data == null) {
          print('Null data received for from campus rides');
          return [];
        }

        // Handle direct list response
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map(
              (item) =>
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
            ),
          );
        }

        // Handle object with rides/data property
        if (data is Map<String, dynamic>) {
          if (data.containsKey('rides') && data['rides'] is List) {
            return List<Map<String, dynamic>>.from(
              data['rides'].map(
                (item) =>
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
              ),
            );
          }

          if (data.containsKey('data') && data['data'] is List) {
            return List<Map<String, dynamic>>.from(
              data['data'].map(
                (item) =>
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
              ),
            );
          }
        }

        print(
          'Unexpected data format for from campus rides: ${data.runtimeType}',
        );
        return [];
      } else if (response.statusCode == 404) {
        print('No from campus rides found (404)');
        return [];
      } else {
        throw Exception(
          'Failed to fetch from campus rides: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getUserFromCampusRides: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserScheduledRides() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/rides/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Handle empty response body
        if (response.body.trim().isEmpty) {
          print('Empty response body for scheduled rides');
          return [];
        }

        final data = jsonDecode(response.body);

        // Handle null response
        if (data == null) {
          print('Null data received for scheduled rides');
          return [];
        }

        // Handle direct list response
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map(
              (item) =>
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
            ),
          );
        }

        // Handle object with rides/data property
        if (data is Map<String, dynamic>) {
          if (data.containsKey('rides') && data['rides'] is List) {
            return List<Map<String, dynamic>>.from(
              data['rides'].map(
                (item) =>
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
              ),
            );
          }

          if (data.containsKey('data') && data['data'] is List) {
            return List<Map<String, dynamic>>.from(
              data['data'].map(
                (item) =>
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
              ),
            );
          }
        }

        print(
          'Unexpected data format for scheduled rides: ${data.runtimeType}',
        );
        return [];
      } else if (response.statusCode == 404) {
        print('No scheduled rides found (404)');
        return [];
      } else {
        throw Exception(
          'Failed to fetch scheduled rides: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getUserScheduledRides: $e');
      return [];
    }
  }
}
