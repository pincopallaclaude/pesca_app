// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async'; // Import for TimeoutException

class NetworkErrorWithStaleDataException implements Exception {
  final String staleJsonData;
  const NetworkErrorWithStaleDataException(this.staleJsonData);
}

class LocationServicesDisabledException implements Exception {
  final String message = 'Location services are disabled.';
  const LocationServicesDisabledException();
  @override
  String toString() => message;
}

/// Custom exception for API-related errors.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  final String _baseUrl = 'https://pesca-api.onrender.com/api';
  final Duration _cacheTTL = const Duration(hours: 6);

  Future<List<ForecastData>> fetchForecastData(String location) async {
    final prefs = await SharedPreferences.getInstance();
    //const cacheVersion =
    //    '_v2.3'; // Increment the version to invalidate old cache
    final String randomCacheBuster =
        DateTime.now().millisecondsSinceEpoch.toString();
    final cacheVersion = '_debug_${randomCacheBuster}';
    print('[ApiService Log] CACHE BUSTER ACTIVE: $cacheVersion');
    final cacheKey = 'forecast_$location$cacheVersion';
    final cacheTimestampKey = 'timestamp_$location$cacheVersion';
    final cachedData = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getInt(cacheTimestampKey);

    if (cachedData != null && cachedTimestamp != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(lastUpdate) < _cacheTTL) {
        print("CACHE HIT: Fresh data found for $location");
        try {
          return parseForecastData(cachedData);
        } catch (e) {
          print("CORRUPTED CACHE! Deleting and proceeding. Error: $e");
          await prefs.remove(cacheKey);
          await prefs.remove(cacheTimestampKey);
        }
      }
    }

    print("CACHE MISS: Network call for $location");
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/forecast?location=$location'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        print('[ApiService DEBUG] Raw JSON received from backend:');
        print(response.body);

        try {
          final data = parseForecastData(response.body);
          // Save to cache only if parsing was successful
          await prefs.setString(cacheKey, response.body);
          await prefs.setInt(
              cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
          return data;
        } catch (e) {
          print("ERROR PARSING NEW JSON: $e. Backend sent corrupted data.");
          if (cachedData != null) {
            print("Using stale cached data as fallback.");
            return parseForecastData(cachedData); // Retry parsing old data
          }
          throw Exception(
              "Data received from server is invalid and no cached data available.");
        }
      } else {
        throw Exception('Server error code: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      // Ensure TimeoutException is caught correctly here
      print("NETWORK ERROR (Timeout): $e");
      if (cachedData != null) {
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      throw Exception('Network error (timeout) and no cached data available.');
    } catch (e) {
      if (e is NetworkErrorWithStaleDataException) throw e;
      print("NETWORK ERROR: $e");
      if (cachedData != null) {
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      throw Exception(
          'Network error or server unavailable and no cached data available.');
    }
  }

  // The method is PUBLIC to be called by ForecastScreen
  List<ForecastData> parseForecastData(String jsonBody) {
    try {
      final decoded = json.decode(jsonBody);
      final dailyListRaw = (decoded['forecast'] as List<dynamic>?) ?? [];

      final weeklyData = dailyListRaw.map((dayJson) {
        final dayMap = dayJson as Map<String, dynamic>;
        final mappedIcon = _mapWeatherIcon(dayMap['meteoIcon'] ?? '');
        return {
          'day': dayMap['giornoNome'] ?? 'N/A',
          'icon': mappedIcon['icon'],
          'icon_color': mappedIcon['icon_color'],
          'min': (dayMap['temperaturaMin'] as num?)?.round() ?? 0,
          'max': (dayMap['temperaturaMax'] as num?)?.round() ?? 0,
        };
      }).toList();

      return dailyListRaw
          .map((dailyJson) => ForecastData.fromJson(
              dailyJson as Map<String, dynamic>, weeklyData))
          .toList();
    } catch (e) {
      print("[FATAL PARSE ERROR] Unable to parse JSON: $e");
      // If the JSON is truly uncorrectable, return an empty list to avoid the loop.
      // The UI will show "No data".
      return [];
    }
  }

  Map<String, dynamic> _mapWeatherIcon(String iconString) {
    if (iconString.contains('☀️'))
      return {'icon': Icons.wb_sunny, 'icon_color': Colors.yellow.shade600};
    if (iconString.contains('🌧️'))
      return {'icon': Icons.umbrella, 'icon_color': Colors.blue.shade300};
    if (iconString.contains('☁️'))
      return {'icon': Icons.cloud_outlined, 'icon_color': Colors.grey.shade400};
    return {'icon': Icons.help_outline, 'icon_color': Colors.grey};
  }

  Future<List<dynamic>> fetchAutocompleteSuggestions(String query) async {
    final url =
        Uri.parse('$_baseUrl/autocomplete?text=${Uri.encodeComponent(query)}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        if (decodedBody is List) return decodedBody;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, String>> getCurrentGpsLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissions permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition();

    final reverseUrl = Uri.parse(
        '$_baseUrl/reverse-geocode?lat=${position.latitude}&lon=${position.longitude}');
    try {
      final response =
          await http.get(reverseUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final locationName = decoded['name'] as String? ?? 'Unknown Location';
        return {
          'coords': "${position.latitude},${position.longitude}",
          'name': locationName.split(',')[0],
        };
      } else {
        throw Exception('Location service not available.');
      }
    } catch (e) {
      throw Exception('Network error searching for location.');
    }
  }

  /// Fetches the AI-generated analysis for the day.
  /// Throws [ApiException] on server errors or timeout.
  Future<String> getAnalysis(double lat, double lon) async {
    // Note: lat/lon are not used by the POC backend, but are included for future-proofing.
    final uri = Uri.parse('$_baseUrl/analyze-day'); // Corrected path
    print('[ApiService Log] Calling: $uri');

    try {
      final response = await http.post(uri).timeout(
            // The timeout must be longer than the simulated delay in the backend
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('API timeout for analysis after 15s'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('[ApiService Log] Analysis received successfully');
        return data['analysis'] as String? ?? 'No analysis available.';
      } else {
        print(
            '[ApiService Log] HTTP error for analysis: ${response.statusCode}');
        throw ApiException('Server error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('[ApiService Log] Analysis timeout: $e');
      throw ApiException('Timeout during analysis request.');
    } catch (e) {
      print('[ApiService Log] Generic analysis ERROR: $e');
      throw ApiException('Unexpected error during analysis.');
    }
  }
}
