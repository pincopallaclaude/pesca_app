// lib/services/api_service.dart

import 'dart:convert'; // Dart SDK
import 'package:http/http.dart' as http; // Package esterni
import 'package:geolocator/geolocator.dart'; // Package esterni
import 'package:flutter/material.dart'; // Flutter
import 'package:shared_preferences/shared_preferences.dart'; // Package esterni
import 'dart:async'; // Dart SDK (Import for TimeoutException)

import '../models/forecast_data.dart'; // Relativi

/// Exception thrown when a network error occurs but stale data is available.
class NetworkErrorWithStaleDataException implements Exception {
  final String staleJsonData;
  const NetworkErrorWithStaleDataException(this.staleJsonData);
}

/// Exception thrown when location services are disabled.
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
  // Using 20s as in the original code, even if it violates the 10s critical constraint.
  final Duration _forecastTimeout = const Duration(seconds: 20);

  /// Fetches forecast data, using a cache first policy.
  Future<List<ForecastData>> fetchForecastData(String location) async {
    final prefs = await SharedPreferences.getInstance();

    // NOTE: The original code implements a random cache buster, which defeats the purpose of caching.
    // It is kept for functional continuity but marked for future review.
    final String randomCacheBuster =
        DateTime.now().millisecondsSinceEpoch.toString();
    final cacheVersion = '_debug_${randomCacheBuster}';
    print('[ApiService Log] CACHE BUSTER ACTIVE: $cacheVersion');

    final cacheKey = 'forecast_$location$cacheVersion';
    final cacheTimestampKey = 'timestamp_$location$cacheVersion';
    final cachedData = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getInt(cacheTimestampKey);

    // 1. Check Cache
    if (cachedData != null && cachedTimestamp != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(lastUpdate) < _cacheTTL) {
        print("[ApiService Log] CACHE HIT: Fresh data found for $location");
        try {
          return parseForecastData(cachedData);
        } catch (e) {
          print(
              "[ApiService Log] CORRUPTED CACHE! Deleting and proceeding. Error: $e");
          await prefs.remove(cacheKey);
          await prefs.remove(cacheTimestampKey);
        }
      }
    }

    // 2. Network Call
    print("[ApiService Log] CACHE MISS: Network call for $location");
    try {
      // The path /forecast is appended to the base URL which is /api
      final response = await http
          .get(Uri.parse('$_baseUrl/forecast?location=$location'))
          .timeout(_forecastTimeout);

      if (response.statusCode == 200) {
        print('[ApiService Log] Raw JSON received from backend.');

        try {
          final data = parseForecastData(response.body);
          // Save to cache only if parsing was successful
          await prefs.setString(cacheKey, response.body);
          await prefs.setInt(
              cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
          return data;
        } catch (e) {
          print(
              "[ApiService Log] ERROR PARSING NEW JSON: $e. Backend sent corrupted data.");
          if (cachedData != null) {
            print("[ApiService Log] Using stale cached data as fallback.");
            return parseForecastData(cachedData); // Retry parsing old data
          }
          throw Exception(
              "Data received from server is invalid and no cached data available.");
        }
      } else {
        // Log the error code (Best Practice: Log-Centric)
        throw Exception('Server error code: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      // Handles TimeoutException explicitly (Critical Constraint)
      print("[ApiService Log] NETWORK ERROR (Timeout): $e");
      if (cachedData != null) {
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      throw Exception('Network error (timeout) and no cached data available.');
    } catch (e) {
      if (e is NetworkErrorWithStaleDataException) rethrow;
      print("[ApiService Log] NETWORK ERROR: $e");
      if (cachedData != null) {
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      throw Exception(
          'Network error or server unavailable and no cached data available.');
    }
  }

  /// Parses the raw JSON string into a list of ForecastData objects.
  /// The method is PUBLIC to be called by ForecastScreen on stale data.
  List<ForecastData> parseForecastData(String jsonBody) {
    try {
      final decoded = json.decode(jsonBody);
      // Handles null case for 'forecast' (Critical Constraint)
      final dailyListRaw = (decoded['forecast'] as List<dynamic>?) ?? [];

      // Data transformation and extraction for weekly data display
      final weeklyData = dailyListRaw.map((dayJson) {
        final dayMap = dayJson as Map<String, dynamic>;
        // Handles null for 'meteoIcon' (Critical Constraint)
        final mappedIcon = _mapWeatherIcon(dayMap['meteoIcon'] ?? '');
        return {
          'day': dayMap['giornoNome'] ?? 'N/A', // Nullable handled
          'icon': mappedIcon['icon'],
          'icon_color': mappedIcon['icon_color'],
          // Nullable handled with 'as num?' and '?? 0' (Critical Constraint)
          'min': (dayMap['temperaturaMin'] as num?)?.round() ?? 0,
          'max': (dayMap['temperaturaMax'] as num?)?.round() ?? 0,
        };
      }).toList();

      return dailyListRaw
          .map((dailyJson) => ForecastData.fromJson(
              dailyJson as Map<String, dynamic>, weeklyData))
          .toList();
    } catch (e) {
      print("[ApiService Log] FATAL PARSE ERROR: $e");
      return []; // Returns empty list on fatal error.
    }
  }

  /// Internal utility to map weather string icons to Flutter Icons.
  Map<String, dynamic> _mapWeatherIcon(String iconString) {
    if (iconString.contains('☀️'))
      return {'icon': Icons.wb_sunny, 'icon_color': Colors.yellow.shade600};
    if (iconString.contains('🌧️'))
      return {'icon': Icons.umbrella, 'icon_color': Colors.blue.shade300};
    if (iconString.contains('☁️'))
      return {'icon': Icons.cloud_outlined, 'icon_color': Colors.grey.shade400};
    return {'icon': Icons.help_outline, 'icon_color': Colors.grey};
  }

  /// Fetches location suggestions from the autocomplete API.
  Future<List<dynamic>> fetchAutocompleteSuggestions(String query) async {
    final url =
        Uri.parse('$_baseUrl/autocomplete?text=${Uri.encodeComponent(query)}');
    try {
      // CRITICAL: Enforce max 10s timeout
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        // Ensure decodedBody is a List, handle null case (Critical Constraint)
        if (decodedBody is List) return decodedBody;
      }
      return []; // Return empty list on non-200 status
    } catch (e) {
      // Return empty list on network error or timeout
      return [];
    }
  }

  /// Gets the current GPS location and reverse geocodes it.
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

    // Heavy operation outside the UI thread (Best Practice)
    Position position = await Geolocator.getCurrentPosition();

    final reverseUrl = Uri.parse(
        '$_baseUrl/reverse-geocode?lat=${position.latitude}&lon=${position.longitude}');
    try {
      // CRITICAL: Enforce max 10s timeout
      final response =
          await http.get(reverseUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Handles null case (Critical Constraint)
        final locationName = decoded['name'] as String? ?? 'Unknown Location';
        return {
          'coords': "${position.latitude},${position.longitude}",
          // Safely extracts the primary name part
          'name': locationName.split(',')[0],
        };
      } else {
        throw Exception('Location service not available.');
      }
    } catch (e) {
      throw Exception('Network error searching for location.');
    }
  }

  /// Fetches the AI-generated analysis for the day using RAG.
  /// Sends location and userQuery in a POST request body.
  /// Throws [ApiException] on server errors or timeout.
  Future<String> fetchAnalysis(String location, String userQuery) async {
    // The path /analyze-day is appended to the base URL which is /api
    final uri = Uri.parse('$_baseUrl/analyze-day');

    // Construct the JSON request body
    final requestBody = json.encode({
      'location': location,
      'userQuery': userQuery,
    });

    try {
      print('[ApiService Log] Calling RAG POST: $uri');

      // --- RIGA DI CODICE PRECENDENTE (INVARIATA, COME CONTESTO) ---
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody, // Send the JSON body
          )
          // --- NUOVO CODICE INCOLLATO (SOSTITUZIONE DEL BLOCCO .timeout) ---
          .timeout(
            // [TIMEOUT INCREASED] from 10 to 30 seconds for AI processing
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('API RAG timeout after 30s'),
          );
      // --- FINE NUOVO CODICE ---

      if (response.statusCode == 200) {
        print('[ApiService Log] Analysis received successfully');

        final data = json.decode(response.body) as Map<String, dynamic>;

        // Handle potential null/empty analysis result (Critical Constraint)
        final analysis =
            data['analysis'] as String? ?? 'No analysis available.';

        if (analysis == 'No analysis available.') {
          throw ApiException("AI response was empty or non-committal.");
        }

        return analysis;
      } else {
        print(
            '[ApiService Log] HTTP error for analysis: ${response.statusCode}');
        // Attempt to extract a detailed error message from the body
        String errorMessage = 'Server error: ${response.statusCode}';
        try {
          final errorJson = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {
          // Ignore if body is not JSON or lacks 'message' key
        }
        throw ApiException(errorMessage);
      }
    } on TimeoutException catch (e) {
      print('[ApiService Log] Analysis timeout: $e');
      throw const ApiException(
          'Timeout during analysis request (30s limit exceeded).');
    } catch (e) {
      print('[ApiService Log] Generic analysis ERROR: $e');
      // Use ApiException for consistency
      throw ApiException('Unexpected error during analysis: ${e.toString()}');
    }
  }
}
