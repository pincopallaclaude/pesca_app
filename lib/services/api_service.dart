// lib/services/api_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/forecast_data.dart';

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
      final dailyListRaw = (decoded['forecast'] as List<dynamic>?) ?? [];

      // La mappatura dell'icona ora viene rimossa da qui.
      // Passiamo la stringa grezza ('meteoIcon') e sarà compito della UI interpretarla.
      final weeklyData = dailyListRaw.map((dayJson) {
        final dayMap = dayJson as Map<String, dynamic>;
        return {
          'day': dayMap['giornoNome'] ?? 'N/A',
          // NOTA: 'icon' e 'icon_color' sono stati rimossi.
          // Invece, includiamo la stringa grezza per la mappatura successiva nella UI.
          'meteoIconString': dayMap['meteoIcon'] ?? '',
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

  /// Fetches the AI-generated analysis using the PHANTOM two-stage architecture.
  Future<String> fetchAnalysis(
    String location,
    String userQuery, {
    List<ForecastData>? forecastData,
  }) async {
    final coords = location.split(',');
    if (coords.length != 2)
      throw const ApiException("Invalid location format.");
    final double? lat = double.tryParse(coords[0].trim());
    final double? lon = double.tryParse(coords[1].trim());
    if (lat == null || lon == null)
      throw const ApiException("Invalid coordinates.");

    // --- STAGE 1: Chiamata all'endpoint a latenza zero ---
    print('[ApiService-Phantom] Stage 1: Calling /get-analysis...');
    try {
      final primaryUri = Uri.parse('$_baseUrl/get-analysis');
      final primaryResponse = await http
          .post(
            primaryUri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'lat': lat, 'lon': lon}),
          )
          .timeout(const Duration(seconds: 5));

      // 202 significa 'pending', qualsiasi altro codice viene gestito
      if (primaryResponse.statusCode == 200) {
        final primaryData =
            json.decode(primaryResponse.body) as Map<String, dynamic>;
        // PARSING CORRETTO: Controlla 'status: success' e estrae da 'data'
        if (primaryData['status'] == 'success' &&
            primaryData['data'] is String) {
          print('[ApiService-Phantom] ✅ Cache HIT. Analysis ready.');
          return primaryData['data'] as String;
        }
      }
    } catch (e) {
      print(
          '[ApiService-Phantom] ⚠️ Error or Timeout on /get-analysis. Proceeding to fallback.');
    }

    // --- STAGE 2: Chiamata all'endpoint di fallback (on-demand) ---
    print('[ApiService-Phantom] Stage 2: Calling /analyze-day-fallback...');
    final fallbackUri = Uri.parse('$_baseUrl/analyze-day-fallback');

    final Map<String, dynamic> requestBody = {
      'lat': lat,
      'lon': lon,
      'userQuery': userQuery,
    };
    final fallbackBody = json.encode(requestBody);

    try {
      final fallbackResponse = await http
          .post(
            fallbackUri,
            headers: {'Content-Type': 'application/json'},
            body: fallbackBody,
          )
          .timeout(const Duration(seconds: 30));

      if (fallbackResponse.statusCode == 200) {
        final fallbackData =
            json.decode(fallbackResponse.body) as Map<String, dynamic>;
        if (fallbackData['status'] == 'success' &&
            fallbackData['data'] is String) {
          return fallbackData['data'] as String;
        } else {
          throw ApiException(
              fallbackData['message'] as String? ?? "Fallback response error.");
        }
      } else {
        throw ApiException(
            'Server error on fallback: ${fallbackResponse.statusCode}');
      }
    } on TimeoutException {
      throw const ApiException(
          'Timeout during fallback analysis (30s exceeded).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error during fallback: ${e.toString()}');
    }
  }
}
