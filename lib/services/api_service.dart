// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkErrorWithStaleDataException implements Exception {
  final String staleJsonData;
  const NetworkErrorWithStaleDataException(this.staleJsonData);
}

class LocationServicesDisabledException implements Exception {
  final String message = 'I servizi di localizzazione sono disabilitati.';
  const LocationServicesDisabledException();
  @override
  String toString() => message;
}

class ApiService {
  final String _baseUrl = 'https://pesca-api.onrender.com/api';
  final Duration _cacheTTL = const Duration(hours: 6);

  Future<List<ForecastData>> fetchForecastData(String location) async {
    final prefs = await SharedPreferences.getInstance();
    const cacheVersion =
        '_v2.5'; // Incrementa la versione per invalidare la cache vecchia
    final cacheKey = 'forecast_$location$cacheVersion';
    final cacheTimestampKey = 'timestamp_$location$cacheVersion';
    final cachedData = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getInt(cacheTimestampKey);

    if (cachedData != null && cachedTimestamp != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(lastUpdate) < _cacheTTL) {
        print("CACHE HIT: Dati freschi trovati per $location");
        try {
          return parseForecastData(cachedData);
        } catch (e) {
          print("CACHE CORROTTA! Cancello e procedo. Errore: $e");
          await prefs.remove(cacheKey);
          await prefs.remove(cacheTimestampKey);
        }
      }
    }

    print("CACHE MISS: Chiamata di rete per $location");
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/forecast?location=$location'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        print('[ApiService DEBUG] JSON grezzo ricevuto dal backend:');
        print(response.body);

        try {
          final data = parseForecastData(response.body);
          // Salva in cache solo se il parsing ha avuto successo
          await prefs.setString(cacheKey, response.body);
          await prefs.setInt(
              cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
          return data;
        } catch (e) {
          print(
              "ERRORE DI PARSING DEL JSON NUOVO: $e. Il backend ha inviato dati corrotti.");
          if (cachedData != null) {
            print("Uso i dati obsoleti in cache come fallback.");
            return parseForecastData(
                cachedData); // Riprova a parsare i dati vecchi
          }
          throw Exception(
              "I dati ricevuti dal server sono invalidi e non ci sono dati in cache.");
        }
      } else {
        throw Exception('Codice errore server: ${response.statusCode}');
      }
    } catch (e) {
      if (e is NetworkErrorWithStaleDataException) throw e;
      print("ERRORE DI RETE: $e");
      if (cachedData != null) {
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      throw Exception('Errore di rete e nessun dato in cache disponibile.');
    }
  }

  // Il metodo è PUBBLICO per essere chiamato da ForecastScreen
  List<ForecastData> parseForecastData(String jsonBody) {
    try {
      final decoded = json.decode(jsonBody);
      final dailyListRaw = (decoded['forecast'] as List<dynamic>?) ?? [];

      final weeklyData = dailyListRaw.map((dayJson) {
        final dayMap = dayJson as Map<String, dynamic>;
        final mappedIcon = _mapWeatherIcon(dayMap['meteoIcon'] ?? '');
        return {
          'day': dayMap['giornoNome'] ?? 'N/D',
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
      print("[FATAL PARSE ERROR] Impossibile parsare il JSON: $e");
      // Se il JSON è veramente incorreggibile, restituiamo una lista vuota per evitare il loop.
      // La UI mostrerà "Nessun dato".
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
        throw Exception('Il permesso di localizzazione è stato negato.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permessi negati permanentemente.');
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
            decoded['name'] as String? ?? 'Posizione Sconosciuta';
        return {
          'coords': "${position.latitude},${position.longitude}",
          'name': locationName.split(',')[0],
        };
      } else {
        throw Exception('Servizio di localizzazione non disponibile.');
      }
    } catch (e) {
      throw Exception('Errore di rete nella ricerca della località.');
    }
  }
}
