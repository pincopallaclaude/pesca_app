// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_data.dart';
import 'package:geolocator/geolocator.dart';


/// Eccezione specifica per quando i servizi di localizzazione del dispositivo sono disattivati.
class LocationServicesDisabledException implements Exception {
  final String message = 'I servizi di localizzazione sono disabilitati.';
  const LocationServicesDisabledException();
  @override
  String toString() => message;
}


class ApiService {
  final String _baseUrl = 'https://pesca-api.onrender.com/api';

  Future<List<ForecastData>> fetchForecastData(String location) async {
    final url = Uri.parse('$_baseUrl/forecast?location=$location');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return (decoded['forecast'] as List)
            .map((json) => ForecastData.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Errore nel caricare le previsioni (Codice: ${response.statusCode})');
      }
    } catch (e) {
      // Intercetta errori di timeout o di rete
      throw Exception('Errore di rete: ${e.toString()}');
    }
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