// lib/models/forecast_data.dart

import 'package:flutter/material.dart';
import '../utils/weather_icon_mapper.dart';

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
  final String giornoNome,
      giornoData,
      meteoIcon,
      temperaturaAvg,
      tempMinMax,
      ventoDati,
      pressione,
      umidita,
      mare,
      altaMarea,
      bassaMarea,
      faseLunare,
      alba,
      tramonto,
      finestraMattino,
      finestraSera;
  final double pescaScoreNumeric;
  final List<ScoreReason> pescaScoreReasons;
  final List<Map<String, dynamic>> hourlyData;
  final List<Map<String, dynamic>> weeklyData;
  final List<Map<String, dynamic>> hourlyScores;
  // --- NUOVI CAMPI AGGIUNTI ---
  final String sunriseTime;
  final String sunsetTime;
  final String moonPhase;
  // --- FINE NUOVO CODICE ---

  ForecastData({
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
    required this.pescaScoreNumeric,
    required this.pescaScoreReasons,
    required this.hourlyData,
    required this.weeklyData,
    required this.hourlyScores,
    // --- NUOVI CAMPI NEL COSTRUTTORE ---
    required this.sunriseTime,
    required this.sunsetTime,
    required this.moonPhase,
    // --- FINE NUOVO CODICE ---
  });

  factory ForecastData.fromJson(
      Map<String, dynamic> json, List<Map<String, dynamic>> weeklyData) {
    num safeParseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    final tempAvgNum = safeParseNum(json['temperaturaAvg']);
    final tempMinNum = safeParseNum(json['temperaturaMin']);
    final tempMaxNum = safeParseNum(json['temperaturaMax']);

    final maree = json['maree']?.toString() ?? 'Alta: N/D | Bassa: N/D';
    final mareeParts = maree.split('|');

    final scoreData = json['pescaScoreData'] as Map<String, dynamic>? ?? {};
    print('[ForecastData fromJson DEBUG] Contenuto di scoreData: $scoreData');

    final reasonsList = scoreData['reasons'] as List<dynamic>? ?? [];
    final hourlyScoresList = scoreData['hourlyScores'] as List<dynamic>? ?? [];

    final rawHourly = json['hourly'] as List<dynamic>? ?? [];
    final hourlyDataParsed =
        rawHourly.whereType<Map<String, dynamic>>().toList();

    print(
        '[ForecastData Log] Dati JSON ricevuti per il giorno ${json['giornoData']}:');
    print('[ForecastData Log]   sunriseTime: ${json['sunriseTime']}');
    print('[ForecastData Log]   sunsetTime: ${json['sunsetTime']}');
    print('[ForecastData Log]   moonPhase: ${json['moonPhase']}');

    return ForecastData(
      giornoNome: json['giornoNome']?.toString() ?? 'N/D',
      giornoData: json['giornoData']?.toString() ?? 'N/D',
      meteoIcon: json['meteoIcon']?.toString() ?? '❓',
      temperaturaAvg: tempAvgNum.round().toString(),
      tempMinMax: 'Max: ${tempMaxNum.round()}° Min: ${tempMinNum.round()}°',
      ventoDati: json['ventoDati']?.toString() ?? 'N/D',
      pressione:
          "${json['pressione']?.toString() ?? 'N/D'} hPa ${json['trendPressione']?.toString() ?? ''}",
      umidita: '${json['umidita']?.toString() ?? 'N/D'}%',
      mare:
          "${json['acronimoMare']?.toString() ?? ''} ${json['temperaturaAcqua']?.toString() ?? ''}° ${json['velocitaCorrente']?.toString() ?? ''} kn",
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
      pescaScoreNumeric: safeParseNum(scoreData['numericScore']).toDouble(),
      pescaScoreReasons: reasonsList
          .whereType<Map<String, dynamic>>()
          .map((r) => ScoreReason.fromJson(r))
          .toList(),
      hourlyScores: hourlyScoresList.whereType<Map<String, dynamic>>().toList(),
      hourlyData: hourlyDataParsed,
      weeklyData: weeklyData,
      // --- MAPPATURA NUOVI CAMPI DA JSON ---
      sunriseTime: json['sunriseTime'] as String? ?? 'N/D',
      sunsetTime: json['sunsetTime'] as String? ?? 'N/D',
      moonPhase: json['moonPhase'] as String? ?? 'N/D',
      // --- FINE NUOVO CODICE ---
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
