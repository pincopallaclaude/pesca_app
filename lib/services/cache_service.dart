// /lib/services/cache_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/forecast_data.dart';

class CacheService {
  static const _forecastBoxName = 'forecastCache';
  static const _analysisBoxName = 'analysisCache';
  static const _forecastKey = 'lastForecastJson';
  static const _timestampKey = 'lastUpdated';
  static const _ttl = Duration(hours: 6);

  Box get _forecastBox => Hive.box(_forecastBoxName);
  Box get _analysisBox => Hive.box(_analysisBoxName);

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

  /// Salva il testo dell'analisi AI nella cache.
  Future<void> saveAnalysis(String analysisText, double lat, double lon) async {
    final key = 'analysis_${lat}_$lon';
    final data = {
      'analysis': analysisText,
      'timestamp': DateTime.now().toIso8601String()
    };
    await _analysisBox.put(key, data);
    print('[CacheService] Analisi AI salvata in cache.');
  }

  /// Recupera un'analisi AI valida dalla cache.
  Future<String?> getValidAnalysis(double lat, double lon) async {
    final key = 'analysis_${lat}_$lon';
    final cachedData = _analysisBox.get(key) as Map<dynamic, dynamic>?;
    if (cachedData == null) return null;

    final timestampString = cachedData['timestamp'] as String?;
    final analysisText = cachedData['analysis'] as String?;
    if (timestampString == null || analysisText == null) return null;

    final lastUpdated = DateTime.tryParse(timestampString);
    if (lastUpdated == null || DateTime.now().difference(lastUpdated) > _ttl) {
      return null;
    }
    print('[CacheService] Cache HIT AI: Analisi valida trovata.');
    return analysisText;
  }
}
