// /lib/services/cache_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/forecast_data.dart'; // Assicurati che questo path sia corretto

class CacheService {
  static const _forecastBoxName = 'forecastCache';
  static const _analysisBoxName = 'analysisCache';
  static const _forecastKey = 'lastForecastJson';
  static const _timestampKey = 'lastUpdated';
  static const _ttl = Duration(hours: 6);

  // Le box devono essere aperte prima dell'accesso
  // Assumiamo che Hive sia già inizializzato e le box siano disponibili
  Box get _forecastBox => Hive.box(_forecastBoxName);
  Box get _analysisBox => Hive.box(_analysisBoxName);

  // Genera la chiave di analisi AI, centralizzando la logica
  String _generateAnalysisKey(double lat, double lon) {
    // Usiamo una precisione fissa, come nell'API server (toFixed(3))
    return 'analysis_${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}';
  }

  // ---------------------------------------------------------------------------
  // FORECAST (PREVISIONI METEO)
  // ---------------------------------------------------------------------------

  /// Salva il JSON grezzo delle previsioni nel database Hive.
  Future<void> saveForecast(String forecastJson) async {
    await _forecastBox.put(_forecastKey, forecastJson);
    await _forecastBox.put(_timestampKey, DateTime.now().toIso8601String());
    print('[CacheService] Dati delle previsioni salvati in cache.');
  }

  /// Recupera e parsifica le previsioni dalla cache, se valide.
  Future<List<ForecastData>?> getValidForecast() async {
    final timestampString = _forecastBox.get(_timestampKey) as String?;
    final forecastJson = _forecastBox.get(_forecastKey) as String?;

    if (timestampString == null || forecastJson == null) return null;

    final lastUpdated = DateTime.tryParse(timestampString);
    if (lastUpdated == null || DateTime.now().difference(lastUpdated) > _ttl) {
      return null;
    }

    print('[CacheService] Cache HIT Meteo: Dati validi trovati.');
    return _parseForecastData(forecastJson);
  }

  /// Pulisce la cache delle previsioni.
  Future<void> clearForecastCache() async {
    await _forecastBox.clear();
  }

  /// Metodo privato per parsificare il JSON delle previsioni.
  List<ForecastData> _parseForecastData(String jsonBody) {
    try {
      final decoded = json.decode(jsonBody);
      final dailyListRaw = (decoded['forecast'] as List<dynamic>?) ?? [];
      // Questo blocco 'weeklyData' è una logica specifica del tuo modello ForecastData
      // che assume una necessità di riassumere i dati giornalieri per i massimi/minimi.
      final weeklyData = dailyListRaw
          .map((d) => {
                'day': d['giornoNome'],
                'meteoIconString': d['meteoIcon'],
                'min': (d['temperaturaMin'] as num).round(),
                'max': (d['temperaturaMax'] as num).round()
              })
          .toList();
      return dailyListRaw
          .map((d) => ForecastData.fromJson(d, weeklyData))
          .toList();
    } catch (e) {
      print("[CacheService] ERRORE PARSING METEO: $e. Pulisco cache corrotta.");
      clearForecastCache();
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ANALISI AI (ANALYSIS) - MODIFICATI
  // ---------------------------------------------------------------------------

  /// Salva l'analisi AI nella cache con metadata (nuovo formato).
  Future<void> saveAnalysis(
    double lat,
    double lon,
    String analysisText, {
    Map<String, dynamic>? metadata, // NUOVO: parametro opzionale per i metadati
  }) async {
    final key = _generateAnalysisKey(lat, lon);
    final data = {
      'analysis': analysisText,
      'metadata': metadata, // Aggiunto il campo metadata
      'timestamp':
          DateTime.now().toIso8601String(), // Mantenuto timestamp come stringa
    };
    // Serializza la mappa in stringa (come richiesto dal tuo OLD code)
    await _analysisBox.put(key, jsonEncode(data));
    print('[CacheService] 💾 Analisi AI salvata in cache: $key');
  }

  /// Recupera un'analisi AI valida dalla cache. Ritorna una mappa o null.
  Future<Map<String, dynamic>?> getValidAnalysis(double lat, double lon) async {
    final key = _generateAnalysisKey(lat, lon);
    final cached = _analysisBox.get(key)
        as String?; // Il tuo codice salva una STRINGA JSON
    if (cached == null) return null;

    try {
      final data = json.decode(cached) as Map<String, dynamic>;

      final timestampString = data['timestamp'] as String?;
      final analysisText = data['analysis'] as String?;

      if (timestampString == null || analysisText == null) {
        await _analysisBox.delete(key);
        return null;
      }

      final lastUpdated = DateTime.tryParse(timestampString);
      if (lastUpdated == null ||
          DateTime.now().difference(lastUpdated) > _ttl) {
        await _analysisBox.delete(key);
        print('[CacheService] 🗑️ Analisi AI scaduta eliminata: $key');
        return null;
      }

      print('[CacheService] ✅ Cache HIT AI: Analisi valida trovata.');

      // Ritorna la mappa completa che include analysis e metadata (potrebbe essere null)
      return {
        'analysis': analysisText,
        'metadata': data['metadata'] as Map<String, dynamic>?,
      };
    } catch (e) {
      print(
          '[CacheService] ⚠️ Errore parsing analisi AI: $e. Pulisco cache corrotta.');
      await _analysisBox.delete(key);
      return null;
    }
  }
}
