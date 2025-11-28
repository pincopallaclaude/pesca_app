// /lib/services/api_service.dart

import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Import necessario per HttpClient
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // Import necessario per IOClient
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
  // --- USA L'URL DI RENDER ---
  //final String _baseUrl = 'https://pesca-api.onrender.com/api';

  // --- NUOVA LOGICA: CLIENT HTTP PERSONALIZZATO ---

  final String _baseUrl = 'http://192.168.1.12:10000/api';

  /// Crea un client HTTP con un timeout di connessione personalizzato.
  /// Utile per gestire i "cold start" dei servizi serverless come Render.
  http.Client _createCustomClient({int timeoutSeconds = 60}) {
    final ioc = HttpClient();
    // Imposta il timeout a un livello basso, per stabilire la connessione
    ioc.connectionTimeout = Duration(seconds: timeoutSeconds);
    return IOClient(ioc);
  }

  // --- FINE NUOVA LOGICA ---

  /// Recupera il JSON delle previsioni meteo.
  Future<String> fetchForecastJson(String location) async {
    // --- DEBUG LOGS (Miglioria per Troubleshooting) ---
    print("[ApiService DEBUG] BaseURL configurato: $_baseUrl");
    final targetUri = Uri.parse('$_baseUrl/forecast?location=$location');
    print("[ApiService DEBUG] Tentativo chiamata a: $targetUri");
    // --------------------------------------------------

    print("[ApiService] Inizio chiamata di rete per: $location");
    final client = _createCustomClient();

    try {
      final response = await client.get(targetUri);

      if (response.statusCode == 200) {
        print('[ApiService] Raw JSON ricevuto dal backend.');
        return response.body;
      }
      print("[ApiService DEBUG] Status Code Errato: ${response.statusCode}");
      print("[ApiService DEBUG] Body Errore: ${response.body}");
      throw ApiException('Errore del server: ${response.statusCode}');
    } on TimeoutException {
      print("[ApiService DEBUG] Timeout scaduto");
      throw const ApiException('Timeout di rete (60s) superato.');
    } catch (e) {
      // --- DEBUG ERROR (Fondamentale per capire il crash) ---
      print("[ApiService DEBUG] ECCEZIONE REALE: $e");
      // ----------------------------------------------------

      if (e is ApiException) rethrow;
      throw const ApiException('Errore di rete o server non disponibile.');
    } finally {
      client.close();
    }
  }

  // --- Funzioni per la Ricerca ---

  /// Recupera suggerimenti di località per l'autocomplete.
  Future<List<dynamic>> fetchAutocompleteSuggestions(String query) async {
    final client = _createCustomClient();
    final url = Uri.parse(
      '$_baseUrl/autocomplete?text=${Uri.encodeComponent(query)}',
    );
    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        if (decodedBody is List) return decodedBody;
      }
      return [];
    } catch (e) {
      print('[ApiService] Errore Autocomplete: ${e.toString()}');
      return [];
    } finally {
      client.close();
    }
  }

  /// Ottiene la posizione GPS corrente e la converte in nome località.
  Future<Map<String, String>> getCurrentGpsLocation() async {
    // La logica GPS non cambia
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const LocationServicesDisabledException();
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception('Permesso negato.');
    }
    if (permission == LocationPermission.deniedForever)
      throw Exception('Permessi negati permanentemente.');

    Position position = await Geolocator.getCurrentPosition();

    // La chiamata di rete ora usa il client custom
    final client = _createCustomClient(
        timeoutSeconds: 20); // Timeout più breve per il reverse geocoding
    final reverseUrl = Uri.parse(
        '$_baseUrl/reverse-geocode?lat=${position.latitude}&lon=${position.longitude}');
    try {
      final response = await client.get(reverseUrl);
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
    } finally {
      client.close();
    }
  }

  // --- Funzioni per l'Analisi AI (Phantom/Fallback) ---

  Future<Map<String, dynamic>> getAnalysisFromCache(
      double lat, double lon) async {
    final client =
        _createCustomClient(timeoutSeconds: 10); // Timeout breve per la cache
    try {
      final uri = Uri.parse('$_baseUrl/get-analysis');
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'lat': lat, 'lon': lon}),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Errore controllo cache: ${response.statusCode}');
    } catch (e) {
      print('[ApiService] Errore getAnalysisFromCache: ${e.toString()}');
      return {'status': 'pending'};
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> generateAnalysisFallback(
      double lat, double lon) async {
    final client = _createCustomClient(
        timeoutSeconds: 45); // Timeout lungo per la generazione AI
    final uri = Uri.parse('$_baseUrl/analyze-day-fallback');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'lat': lat, 'lon': lon}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        if (result.containsKey('analysis') && result.containsKey('metadata')) {
          return result;
        }
        throw const ApiException('Risposta di fallback malformata.');
      }
      throw ApiException('Errore fallback: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Errore inatteso fallback: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  /// Invia il feedback dell'utente al backend.
  ///
  /// [feedbackData] deve essere una mappa contenente le informazioni
  /// raccolte dal dialogo di feedback (es. sessionId, outcome, species, notes).
  Future<bool> submitFeedback(Map<String, dynamic> feedbackData) async {
    print("[ApiService] Invio feedback al backend...");
    final client = _createCustomClient(
        timeoutSeconds: 20); // Timeout standard per una chiamata POST
    final uri = Uri.parse('$_baseUrl/submit-feedback');

    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(feedbackData),
      );

      if (response.statusCode == 200) {
        print("[ApiService] ✅ Feedback inviato con successo.");
        return true;
      } else {
        print(
            "[ApiService] ⚠️ Errore invio feedback: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print(
          "[ApiService] ❌ Errore di rete durante l'invio del feedback: ${e.toString()}");
      return false;
    } finally {
      client.close();
    }
  }
}
