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
  // Questi campi vengono mantenuti per non rompere i widget esistenti (es. MainHeroModule)
  // Saranno progressivamente eliminati man mano che refattorizziamo.
  final String giornoNome, giornoData, meteoIcon, temperaturaAvg, tempMinMax;
  final String ventoDati, pressione, umidita, mare, altaMarea, bassaMarea;
  final String faseLunare, alba, tramonto, finestraMattino, finestraSera;
  final List<ScoreReason> pescaScoreReasons;
  final List<Map<String, dynamic>> hourlyData;
  final List<Map<String, dynamic>> weeklyData;
  final List<Map<String, dynamic>> hourlyScores;

  // --- SEZIONE 2: Nuovi campi per funzionalità avanzate ---
  // Dati PURI (numerici) usati dai nuovi widget (es. WeeklyForecast)
  final double pescaScoreNumeric;
  final double temperaturaMax;
  final double temperaturaMin;
  final String trendPressione;
  final String dailyWeatherCode;
  final int dailyHumidity;
  final int dailyPressure;
  final int dailyWindSpeedKn;
  final int dailyWindDirectionDegrees;
  final String sunriseTime; // Orari puliti senza icone
  final String sunsetTime;
  final String moonPhase; // Testo pulito per il mapper

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
    /// FUNZIONE HELPER ROBUSTA PER IL PARSING
    /// Converte in modo sicuro qualsiasi valore (num, String, null) in un numero.
    num safeParseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    if (kDebugMode) {
      print(
          '[ForecastData Log] Parsing JSON per giorno: ${json['giornoData']}');
    }

    final scoreData = json['pescaScoreData'] as Map<String, dynamic>? ?? {};
    final maree = json['maree']?.toString() ?? 'Alta: N/D | Bassa: N/D';
    final mareeParts = maree.split('|');

    return ForecastData(
      // Sezione 1: Campi String legacy
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

// --- NUOVO CODICE DA INCOLLARE (IN SOSTITUZIONE DELLA RIGA `mare:`) ---
      // Logica di fallback robusta: Prova a leggere la nuova chiave 'mare'.
      // Se non c'è (cache vecchia), la ricostruisce con i vecchi campi.
      mare: json['mare']?.toString() ??
          '${json['acronimoMare']?.toString() ?? ""} ${json['temperaturaAcqua']?.toString() ?? ""}° ${json['velocitaCorrente']?.toString() ?? ""} kn'
              .trim(),
// --- FINE NUOVO CODICE ---

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
      pescaScoreReasons: ((scoreData['reasons'] as List?) ?? [])
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

      // --- Sezione 2: Campi PURI, PARSATI IN MODO SICURO ---
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
      sunriseTime:
          json['sunriseTime'] as String? ?? 'N/D', // Nuovo campo pulito
      sunsetTime: json['sunsetTime'] as String? ?? 'N/D', // Nuovo campo pulito
      moonPhase: json['moonPhase'] as String? ?? 'N/D', // Nuovo campo pulito
    );
  }

  /// Restituisce la previsione oraria più vicina al momento attuale.
  Map<String, dynamic> get currentHourData {
    if (hourlyData.isEmpty) {
      return {
        'time': '--:--',
        'tempC': temperaturaAvg.replaceAll('°', ''),
        'weatherCode': '0',
      };
    }

    final now = DateTime.now();
    final currentHour = hourlyData.firstWhere(
      (hour) {
        final hourTime =
            int.tryParse(hour['time']?.split(':')[0] ?? '-1') ?? -1;
        return hourTime >= now.hour;
      },
      orElse: () => hourlyData.last,
    );
    return currentHour;
  }

  /// Restituisce la lista di previsioni orarie da mostrare nella riga orizzontale.
  List<Map<String, dynamic>> get hourlyForecastForDisplay {
    if (hourlyData.isEmpty) return [];
    final now = DateTime.now();
    final int currentHourInt = now.hour;

    return hourlyData.where((hour) {
      final hourStr = (hour['time'] as String?)?.split(':')[0];
      if (hourStr == null) return false;
      final hourTime = int.tryParse(hourStr);
      if (hourTime == null) return false;
      return hourTime > currentHourInt;
    }).toList();
  }

  String get backgroundImagePath {
    try {
      DateTime _parseTime(String timeStr) {
        final now = DateTime.now();
        final parts = timeStr.split(':');
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]),
            int.parse(parts[1]));
      }

      final oraCorrente = DateTime.now();
      final oraAlba = _parseTime(alba);
      final oraTramonto = _parseTime(tramonto);
      final unOraPrimaAlba = oraAlba.subtract(const Duration(hours: 1));
      final unOraDopoAlba = oraAlba.add(const Duration(hours: 1));
      final unOraPrimaTramonto = oraTramonto.subtract(const Duration(hours: 1));
      final unOraDopoTramonto = oraTramonto.add(const Duration(hours: 1));

      if ((oraCorrente.isAfter(unOraPrimaAlba) &&
              oraCorrente.isBefore(unOraDopoAlba)) ||
          (oraCorrente.isAfter(unOraPrimaTramonto) &&
              oraCorrente.isBefore(unOraDopoTramonto))) {
        return 'assets/background_sunset.jpg';
      }
      if (oraCorrente.isBefore(oraAlba) || oraCorrente.isAfter(oraTramonto)) {
        return 'assets/background_nocturnal.jpg';
      }
      final condizioneMeteo = meteoIcon.toLowerCase();
      if (condizioneMeteo.contains('rain') ||
          condizioneMeteo.contains('shower') ||
          condizioneMeteo.contains('thunder') ||
          condizioneMeteo.contains('pioggia') ||
          condizioneMeteo.contains('temporale')) {
        return 'assets/background_rainy.jpg';
      }
      return 'assets/background_daily.jpg';
    } catch (e) {
      return 'assets/background_daily.jpg';
    }
  }
}
