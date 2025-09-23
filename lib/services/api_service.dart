// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Eccezione per quando la rete fallisce ma esistono dati obsoleti in cache.
class NetworkErrorWithStaleDataException implements Exception {
  /// Il JSON dei dati obsoleti, pronto per essere parsato.
  final String staleJsonData;
  const NetworkErrorWithStaleDataException(this.staleJsonData);
}
// --- FI

/// Eccezione specifica per quando i servizi di localizzazione del dispositivo sono disattivati.
class LocationServicesDisabledException implements Exception {
  final String message = 'I servizi di localizzazione sono disabilitati.';
  const LocationServicesDisabledException();
  @override
  String toString() => message;
}


class ApiService {
  final String _baseUrl = 'https://pesca-api.onrender.com/api';

  /// Converte una stringa/emoji dall'API in un'icona e colore per la UI.
  final Duration _cacheTTL = const Duration(hours: 6); // Time-To-Live per la cache

  /// Converte una stringa/emoji dall'API in un'icona e colore per la UI.
  Map<String, dynamic> _mapWeatherIcon(String iconString) {
    final lowerIcon = iconString.toLowerCase();
    if (lowerIcon.contains('☀️') || lowerIcon.contains('sunny') || lowerIcon.contains('clear')) {
      return {'icon': Icons.wb_sunny, 'icon_color': Colors.yellow.shade600};
    } else if (lowerIcon.contains('🌧️') || lowerIcon.contains('rain') || lowerIcon.contains('shower')) {
      return {'icon': Icons.umbrella, 'icon_color': Colors.blue.shade300};
    } else if (lowerIcon.contains('☁️') || lowerIcon.contains('cloud')) {
      return {'icon': Icons.cloud_outlined, 'icon_color': Colors.grey.shade400};
    }
    return {'icon': Icons.help_outline, 'icon_color': Colors.grey};
  }

  Future<List<ForecastData>> fetchForecastData(String location) async {
    final url = Uri.parse('$_baseUrl/forecast?location=$location');
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'forecast_$location';
    final cacheTimestampKey = 'timestamp_$location';

    // 1. VERIFICA CACHE "FRESCA"
    final cachedData = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getInt(cacheTimestampKey);

    if (cachedData != null && cachedTimestamp != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(lastUpdate) < _cacheTTL) {
        print("CACHE HIT: Dati freschi trovati per $location");
        return parseForecastData(cachedData);       }
    }

    // 2. CACHE MISS O DATI SCADUTI: PROCEDI CON LA CHIAMATA DI RETE
    print("CACHE MISS: Chiamata di rete per $location");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        // Salva i nuovi dati e il timestamp
        await prefs.setString(cacheKey, response.body);
        await prefs.setInt(cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
        return parseForecastData(response.body); // Usa il metodo pubblico
      } else {
        throw Exception('Codice errore: ${response.statusCode}');
      }
    } catch (e) {
      // 3. ERRORE DI RETE: GESTISCI FALLBACK
      print("ERRORE RETE: $e");
      // Se la chiamata fallisce, controlla se esistono dati (anche se obsoleti)
      if (cachedData != null) {
        // Se esistono, lancia la nostra eccezione personalizzata con i dati vecchi
        throw NetworkErrorWithStaleDataException(cachedData);
      }
      // Se non ci sono neanche dati vecchi, lancia un'eccezione generica
      throw Exception('Errore di rete e nessun dato in cache disponibile.');
    }
  }

  /// Metodo helper centralizzato per parsare il JSON. Evita la duplicazione del codice.
  // Ora è PUBBLICO, senza il carattere '_' iniziale.
  List<ForecastData> parseForecastData(String jsonBody) {
    final decoded = json.decode(jsonBody);
    final dailyListRaw = (decoded['forecast'] as List<dynamic>?) ?? [];

    final weeklyData = dailyListRaw.map((dayJson) {
      final mappedIcon = _mapWeatherIcon(dayJson['meteoIcon'] ?? '');
      return {
        'day': dayJson['giornoNome'] ?? 'N/D',
        'icon': mappedIcon['icon'],
        'icon_color': mappedIcon['icon_color'],
        'min': dayJson['temperaturaMin'] as int? ?? 0,
        'max': dayJson['temperaturaMax'] as int? ?? 0,
      };
    }).toList();

    // Questa chiamata ora corrisponde ESATTAMENTE alla firma del costruttore corretta.
    return dailyListRaw
        .map((dailyJson) =>
            ForecastData.fromJson(dailyJson as Map<String, dynamic>, weeklyData))
        .toList();
  }

  Future<List<dynamic>> fetchAutocompleteSuggestions(String query) async {
    if (query.length < 3) return [];
    
    final url = Uri.parse('$_baseUrl/autocomplete?text=${Uri.encodeComponent(query)}');
    try {
        final response = await http.get(url).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final decodedBody = json.decode(response.body);
          if (decodedBody is List) return decodedBody;
        }
        return [];
    } catch (e) {
        return []; // In caso di errore (es. timeout), restituisce lista vuota
    }
  }

  /// Gestisce i permessi, recupera le coordinate GPS e le converte in un nome
  /// di località tramite l'API di reverse geocoding.
  Future<Map<String, String>> getCurrentGpsLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Controlla se il servizio di localizzazione è attivo.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException();
    }

    // 2. Controlla e richiede i permessi.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Il permesso di localizzazione è stato negato.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permessi negati permanentemente. Abilitali dalle impostazioni.');
    } 

    // 3. Recupera le coordinate GPS.
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    // 4. Converte le coordinate in un nome di località.
    final reverseUrl = Uri.parse('$_baseUrl/reverse-geocode?lat=${position.latitude}&lon=${position.longitude}');
    try {
      final response = await http.get(reverseUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final locationName = decoded['name'] as String? ?? 'Posizione Sconosciuta';
        return {
          'coords': "${position.latitude},${position.longitude}",
          // Prende solo la parte principale del nome (es. "Napoli" da "Napoli, IT")
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