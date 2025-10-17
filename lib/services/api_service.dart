// /lib/services/api_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/forecast_data.dart';

// Ripristiniamo l'eccezione, che è richiesta da forecast_screen.dart
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

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  final String _baseUrl = 'https://pesca-api-v5.fly.dev/api';
  final Duration _cacheTTL = const Duration(hours: 6);
  final Duration _forecastTimeout = const Duration(seconds: 20);

  Future<List<ForecastData>> fetchForecastData(String location) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'forecast_$location';
    final cacheTimestampKey = 'timestamp_$location';
    final cachedData = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getInt(cacheTimestampKey);

    if (cachedData != null && cachedTimestamp != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(lastUpdate) < _cacheTTL) {
        print(
            "[ApiService] CACHE HIT (SharedPreferences): Dati freschi trovati.");
        return parseForecastData(cachedData);
      }
    }

    print("[ApiService] CACHE MISS: Chiamata di rete.");
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/forecast?location=$location'))
          .timeout(_forecastTimeout);

      if (response.statusCode == 200) {
        final data = parseForecastData(response.body);
        await prefs.setString(cacheKey, response.body);
        await prefs.setInt(
            cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
        return data;
      } else {
        throw Exception('Errore del server: ${response.statusCode}');
      }
    } on TimeoutException {
      if (cachedData != null) {
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      throw Exception('Errore di rete (timeout) e nessun dato in cache.');
    } catch (e) {
      if (e is NetworkErrorWithStaleDataException) rethrow;
      if (cachedData != null) {
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      throw Exception('Errore di rete o server non disponibile.');
    }
  }

  List<ForecastData> parseForecastData(String jsonBody) {
    try {
      final decoded = json.decode(jsonBody);
      final dailyListRaw = (decoded['forecast'] as List<dynamic>?) ?? [];
      final weeklyData = dailyListRaw.map((dayJson) {
        final dayMap = dayJson as Map<String, dynamic>;
        return {
          'day': dayMap['giornoNome'] ?? 'N/A',
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
      print("[ApiService] ERRORE DI PARSING: $e");
      return [];
    }
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
        throw Exception('Permesso di localizzazione negato.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permessi di localizzazione negati permanentemente.');
    }
    Position position = await Geolocator.getCurrentPosition();
    final reverseUrl = Uri.parse(
        '$_baseUrl/reverse-geocode?lat=${position.latitude}&lon=${position.longitude}');
    try {
      final response =
          await http.get(reverseUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final locationName =
            decoded['name'] as String? ?? 'Località Sconosciuta';
        return {
          'coords': "${position.latitude},${position.longitude}",
          'name': locationName.split(',')[0],
        };
      } else {
        throw Exception('Servizio di localizzazione non disponibile.');
      }
    } catch (e) {
      throw Exception('Errore di rete durante la ricerca della località.');
    }
  }

  Future<String> fetchAnalysis(String location, String userQuery,
      {List<ForecastData>? forecastData}) async {
    final coords = location.split(',');
    if (coords.length != 2)
      throw const ApiException("Formato località non valido.");
    final double? lat = double.tryParse(coords[0].trim());
    final double? lon = double.tryParse(coords[1].trim());
    if (lat == null || lon == null)
      throw const ApiException("Coordinate non valide.");
    const int maxRetries = 2;
    for (int i = 0; i < maxRetries; i++) {
      try {
        final primaryUri = Uri.parse('$_baseUrl/get-analysis');
        final primaryResponse = await http
            .post(
              primaryUri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'lat': lat, 'lon': lon}),
            )
            .timeout(const Duration(seconds: 10));
        final primaryData =
            json.decode(primaryResponse.body) as Map<String, dynamic>;
        if (primaryResponse.statusCode == 200 &&
            primaryData['status'] == 'success' &&
            primaryData['data'] is String) {
          return primaryData['data'] as String;
        }
        break;
      } catch (e) {
        if (i >= maxRetries - 1) {
          print(
              '[ApiService-Phantom] Errore finale in /get-analysis. Procedo al fallback.');
        }
      }
    }
    final fallbackUri = Uri.parse('$_baseUrl/analyze-day-fallback');
    final Map<String, dynamic> requestBody = {
      'lat': lat,
      'lon': lon,
      'userQuery': userQuery
    };
    try {
      final fallbackResponse = await http
          .post(
            fallbackUri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      if (fallbackResponse.statusCode == 200) {
        final fallbackData =
            json.decode(fallbackResponse.body) as Map<String, dynamic>;
        if (fallbackData['status'] == 'success' &&
            fallbackData['data'] is String) {
          return fallbackData['data'] as String;
        }
      }
      throw ApiException('Errore nella risposta di fallback.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Errore inatteso durante il fallback: ${e.toString()}');
    }
  }
}
