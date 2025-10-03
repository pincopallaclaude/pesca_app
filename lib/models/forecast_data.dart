// lib/models/forecast_data.dart

import 'package:flutter/material.dart';
import '../utils/weather_icon_mapper.dart';
import 'package:flutter/foundation.dart';

class ScoreReason {
  final String icon, text, points, type;

  const ScoreReason({
    required this.icon,
    required this.text,
    required this.points,
    required this.type,
  });

  factory ScoreReason.fromJson(Map<String, dynamic> json) => ScoreReason(
        icon: json['icon'] ?? 'pressure',
        text: json['text'] ?? 'N/D',
        points: json['points'] ?? '+0.0',
        type: json['type'] ?? 'neutral',
      );
}

class ForecastData {
  // --- SEZIONE 1: Vecchi campi per retrocompatibilità ---
  final String giornoNome, giornoData, meteoIcon, temperaturaAvg, tempMinMax;
  final String ventoDati, pressione, umidita, mare, altaMarea, bassaMarea;
  final String faseLunare, alba, tramonto, finestraMattino, finestraSera;
  final List<ScoreReason> pescaScoreReasons;
  final List<Map<String, dynamic>> hourlyData;
  final List<Map<String, dynamic>> weeklyData;
  final List<Map<String, dynamic>> hourlyScores;

  // --- SEZIONE 2: Nuovi campi per funzionalità avanzate ---
  final double pescaScoreNumeric;
  final double temperaturaMax;
  final double temperaturaMin;
  final String trendPressione;
  final String dailyWeatherCode;
  final int dailyHumidity;
  final int dailyPressure;
  final int dailyWindSpeedKn;
  final int dailyWindDirectionDegrees;
  final String sunriseTime; // Orari puliti
  final String sunsetTime;
  final String moonPhase;

  ForecastData({
    // Sezione 1
    required this.giornoNome,
    required this.giornoData,
    required this.meteoIcon,
    required this.temperaturaAvg,
    required this.tempMinMax,
    required this.ventoDati,
    required this.pressione,
    required this.umidita,
    required this.mare,
    required this.altaMarea,
    required this.bassaMarea,
    required this.faseLunare,
    required this.alba,
    required this.tramonto,
    required this.finestraMattino,
    required this.finestraSera,
    required this.pescaScoreReasons,
    required this.hourlyData,
    required this.weeklyData,
    required this.hourlyScores,
    // Sezione 2
    required this.pescaScoreNumeric,
    required this.temperaturaMax,
    required this.temperaturaMin,
    required this.trendPressione,
    required this.dailyWeatherCode,
    required this.dailyHumidity,
    required this.dailyPressure,
    required this.dailyWindSpeedKn,
    required this.dailyWindDirectionDegrees,
    required this.sunriseTime,
    required this.sunsetTime,
    required this.moonPhase,
  });

  factory ForecastData.fromJson(
      Map<String, dynamic> json, List<Map<String, dynamic>> weeklyData) {
    num safeParseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    if (kDebugMode) {
      debugPrint(
          '[ForecastData Log] Parsing JSON per giorno: ${json['giornoData']}');
    }

    final scoreData = json['pescaScoreData'] as Map<String, dynamic>? ?? {};
    final maree = json['maree']?.toString() ?? 'Alta: N/D | Bassa: N/D';
    final mareeParts = maree.split('|');

    final List<dynamic> dailyReasonsRaw = scoreData['reasons'] as List? ?? [];
    if (kDebugMode && !scoreData.containsKey('reasons')) {
      print(
          "!!! ATTENZIONE: La chiave 'reasons' NON è presente in 'pescaScoreData' per il giorno ${json['giornoData']}. La lista sarà vuota. !!!");
    }

    return ForecastData(
      giornoNome: json['giornoNome']?.toString() ?? 'N/D',
      giornoData: json['giornoData']?.toString() ?? 'N/D',
      meteoIcon: json['meteoIcon']?.toString() ?? '❓',
      temperaturaAvg: safeParseNum(json['temperaturaAvg']).round().toString(),
      tempMinMax:
          'Max: ${safeParseNum(json['temperaturaMax']).round()}° Min: ${safeParseNum(json['temperaturaMin']).round()}°',
      ventoDati: json['ventoDati']?.toString() ?? 'N/D',
      pressione:
          "${json['pressione']?.toString() ?? 'N/D'} hPa ${json['trendPressione']?.toString() ?? ''}",
      umidita: '${json['umidita']?.toString() ?? 'N/D'}%',
      mare: json['mare']?.toString() ??
          '${json['acronimoMare']?.toString() ?? ""} ${json['temperaturaAcqua']?.toString() ?? ""}° ${json['velocitaCorrente']?.toString() ?? ""} kn'
              .trim(),
      altaMarea: mareeParts.isNotEmpty
          ? mareeParts[0].replaceFirst('Alta:', '').trim()
          : 'N/D',
      bassaMarea: mareeParts.length > 1
          ? mareeParts[1].replaceFirst('Bassa:', '').trim()
          : 'N/D',
      faseLunare: json['faseLunare']?.toString() ?? 'N/D',
      alba: json['alba']?.toString()?.replaceFirst('☀️', '').trim() ?? 'N/D',
      tramonto: json['tramonto']?.toString() ?? 'N/D',
      finestraMattino:
          (json['finestraMattino'] as Map<String, dynamic>)?['orario']
                  ?.toString() ??
              'N/D',
      finestraSera: (json['finestraSera'] as Map<String, dynamic>)?['orario']
              ?.toString() ??
          'N/D',
      pescaScoreReasons: dailyReasonsRaw
          .whereType<Map<String, dynamic>>()
          .map((r) => ScoreReason.fromJson(r))
          .toList(),
      hourlyData: ((json['hourly'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      weeklyData: weeklyData,
      hourlyScores: ((scoreData['hourlyScores'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      pescaScoreNumeric: safeParseNum(scoreData['numericScore']).toDouble(),
      temperaturaMax: safeParseNum(json['temperaturaMax']).toDouble(),
      temperaturaMin: safeParseNum(json['temperaturaMin']).toDouble(),
      trendPressione: json['trendPressione'] as String? ?? '→',
      dailyWeatherCode: json['dailyWeatherCode'] as String? ?? '0',
      dailyHumidity: safeParseNum(json['dailyHumidity']).toInt(),
      dailyPressure: safeParseNum(json['dailyPressure']).toInt(),
      dailyWindSpeedKn: safeParseNum(json['dailyWindSpeedKn']).toInt(),
      dailyWindDirectionDegrees:
          safeParseNum(json['dailyWindDirectionDegrees']).toInt(),
      sunriseTime: json['sunriseTime'] as String? ?? 'N/D',
      sunsetTime: json['sunsetTime'] as String? ?? 'N/D',
      moonPhase: json['moonPhase'] as String? ?? 'N/D',
    );
  }

  Map<String, dynamic> get currentHourData {
    if (hourlyData.isEmpty) {
      return {
        'time': '--:--',
        'tempC': temperaturaAvg.replaceAll('°', ''),
        'weatherCode': '0'
      };
    }
    final now = DateTime.now();
    return hourlyData.firstWhere(
      (hour) {
        final hourTime =
            int.tryParse(hour['time']?.split(':')[0] ?? '-1') ?? -1;
        return hourTime >= now.hour;
      },
      orElse: () => hourlyData.last,
    );
  }

  List<Map<String, dynamic>> get hourlyForecastForDisplay {
    if (hourlyData.isEmpty) return [];
    final now = DateTime.now();
    final int currentHourInt = now.hour;

    return hourlyData.where((hour) {
      final hourStr = (hour['time'] as String?)?.split(':')[0];
      if (hourStr == null) return false;
      final hourTime = int.tryParse(hourStr);
      if (hourTime == null) return false;
      return hourTime >= currentHourInt;
    }).toList();
  }

  String get backgroundImagePath {
    const rainyWeatherCodes = {
      '176',
      '263',
      '266',
      '281',
      '284',
      '293',
      '296',
      '299',
      '302',
      '305',
      '308',
      '311',
      '314',
      '353',
      '356',
      '359',
      '386',
      '389'
    };
    const snowyWeatherCodes = {
      '179',
      '182',
      '185',
      '227',
      '230',
      '323',
      '326',
      '329',
      '332',
      '335',
      '338',
      '368',
      '371'
    };

    try {
      DateTime? _parseTime(String timeStr) {
        if (timeStr == 'N/D' || !timeStr.contains(':')) return null;
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) return null;
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }

      final oraCorrente = DateTime.now();
      final oraAlba = _parseTime(sunriseTime);
      final oraTramonto = _parseTime(sunsetTime);
      final currentHourWeatherCode = currentHourData['weatherCode']?.toString();

      if (kDebugMode) {
        debugPrint("\n--- [BACKGROUND DEBUG] Inizio Analisi ---");
        debugPrint("[BACKGROUND DEBUG] Ora Corrente: $oraCorrente");
        debugPrint(
            "[BACKGROUND DEBUG] Dati Orari: sunriseTime='$sunriseTime', sunsetTime='$sunsetTime'");
        debugPrint(
            "[BACKGROUND DEBUG] Codici Meteo: currentHourWeatherCode='$currentHourWeatherCode', dailyWeatherCode='$dailyWeatherCode'");
        debugPrint(
            "[BACKGROUND DEBUG] Orari Parsati: oraAlba=$oraAlba, oraTramonto=$oraTramonto");
        debugPrint("--- Fine Analisi ---\n");
      }

      if (oraAlba == null || oraTramonto == null) {
        if (kDebugMode)
          debugPrint(
              "[BACKGROUND DEBUG] --> DECISIONE: Parsing alba/tramonto fallito. Controllo solo meteo.");
        if (currentHourWeatherCode != null &&
            rainyWeatherCodes.contains(currentHourWeatherCode)) {
          return 'assets/background_rainy.jpg';
        }
        return 'assets/background_daily.jpg';
      }

      if (currentHourWeatherCode != null &&
          (rainyWeatherCodes.contains(currentHourWeatherCode) ||
              snowyWeatherCodes.contains(currentHourWeatherCode))) {
        if (kDebugMode)
          debugPrint(
              "[BACKGROUND DEBUG] --> DECISIONE: METEO AVVERSO ATTUALE (Codice: $currentHourWeatherCode). Ritorno 'rainy'.");
        return 'assets/background_rainy.jpg';
      }

      final trentaMinutiDopoTramonto =
          oraTramonto.add(const Duration(minutes: 30));
      if (oraCorrente.isBefore(oraAlba) ||
          oraCorrente.isAfter(trentaMinutiDopoTramonto)) {
        if (kDebugMode)
          debugPrint(
              "[BACKGROUND DEBUG] --> DECISIONE: Condizione NOCTURNAL soddisfatta.");
        return 'assets/background_nocturnal.jpg';
      }

      final unOraPrimaTramonto = oraTramonto.subtract(const Duration(hours: 1));
      final unOraDopoAlba = oraAlba.add(const Duration(hours: 1));
      if (oraCorrente.isAfter(unOraPrimaTramonto) ||
          oraCorrente.isBefore(unOraDopoAlba)) {
        if (kDebugMode)
          debugPrint(
              "[BACKGROUND DEBUG] --> DECISIONE: Condizione SUNSET/SUNRISE soddisfatta.");
        return 'assets/background_sunset.jpg';
      }

      if (kDebugMode)
        debugPrint(
            "[BACKGROUND DEBUG] --> DECISIONE: Fallback 'daily' finale.");
      return 'assets/background_daily.jpg';
    } catch (e) {
      if (kDebugMode)
        debugPrint(
            "[BACKGROUND DEBUG] --> DECISIONE: ERRORE CATCH GLOBALE: $e.");
      return 'assets/background_daily.jpg';
    }
  }
}
