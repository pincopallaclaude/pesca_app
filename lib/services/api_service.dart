// /lib/services/api_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Eccezione specifica per problemi con i servizi di localizzazione
class LocationServicesDisabledException implements Exception {
  final String message = 'Location services are disabled.';
  const LocationServicesDisabledException();
  @override
  String toString() => message;
}

/// Eccezione generale per errori API (rete o server)
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  // L'URL base del backend
  final String _baseUrl = 'https://pesca-api-v5.fly.dev/api';

  /// Recupera il JSON delle previsioni meteo.
  Future<String> fetchForecastJson(String location) async {
    print("[ApiService] Inizio chiamata di rete per: $location");
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/forecast?location=$location'))
          .timeout(const Duration(seconds: 20)); // Timeout per il meteo

      if (response.statusCode == 200) {
        print('[ApiService] Raw JSON ricevuto dal backend.');
        return response.body;
      }
      throw ApiException('Errore del server: ${response.statusCode}');
    } on TimeoutException {
      throw const ApiException('Timeout di rete (20s) superato.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException('Errore di rete o server non disponibile.');
    }
  }

  // --- Funzioni per la Ricerca ---

  /// Recupera suggerimenti di località per l'autocomplete.
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
      // Ignoriamo gli errori di rete per l'autocomplete e ritorniamo una lista vuota
      print('[ApiService] Errore Autocomplete: ${e.toString()}');
      return [];
    }
  }

  /// Ottiene la posizione GPS corrente e la converte in nome località.
  Future<Map<String, String>> getCurrentGpsLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Controllo servizi di localizzazione
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException();
    }

    // 2. Controllo permessi
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

    // 3. Ottiene posizione e fa reverse geocoding
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

  // --- Funzioni per l'Analisi AI (Phantom/Fallback) ---

  /// [NUOVO] Controlla la cache del backend (endpoint Phantom).
  /// Ritorna una mappa con 'status', 'analysis' (se pronto) e 'metadata'.
  Future<Map<String, dynamic>> getAnalysisFromCache(
      double lat, double lon) async {
    try {
      final uri = Uri.parse('$_baseUrl/get-analysis');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'lat': lat, 'lon': lon}),
          )
          .timeout(const Duration(seconds: 5)); // Timeout breve per la cache

      // Accetta 200 (HIT) o 202 (MISS/PENDING)
      if (response.statusCode == 200 || response.statusCode == 202) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Errore controllo cache: ${response.statusCode}');
    } catch (e) {
      print('[ApiService] Errore getAnalysisFromCache: ${e.toString()}');
      // In caso di errore (timeout, rete, etc.), ritorna 'pending'
      // per far scattare il fallback nel BLoC o ViewModel.
      return {'status': 'pending'};
    }
  }

  /// [NUOVO] Esegue il fallback per generare una nuova analisi on-demand.
  /// Ritorna una mappa con 'analysis' (Stringa Markdown) e 'metadata' (Map).
  Future<Map<String, dynamic>> generateAnalysisFallback(
      double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/analyze-day-fallback');
    try {
      // Inoltriamo lat/lon e l'API decide la query interna da usare.
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'lat': lat, 'lon': lon}),
          )
          .timeout(
              const Duration(seconds: 45)); // Timeout lungo per la generazione

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        // Verifichiamo che la risposta abbia i campi attesi
        if (result.containsKey('analysis') && result.containsKey('metadata')) {
          return result;
        }
        throw const ApiException(
            'Risposta di fallback incompleta o malformata.');
      }
      throw ApiException(
          'Errore nella risposta di fallback: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Errore inatteso durante il fallback: ${e.toString()}');
    }
  }

  // --- Metodo Obsoleto Rimosso ---
  // Il vecchio metodo fetchAnalysis è stato rimosso in quanto obsoleto.
}
