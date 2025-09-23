// lib/models/forecast_data.dart

import 'package:flutter/material.dart';

class ScoreReason {
  final String icon, text, points, type;

  const ScoreReason({required this.icon, required this.text, required this.points, required this.type});

  factory ScoreReason.fromJson(Map<String, dynamic> json) => ScoreReason(
        icon: json['icon'] ?? 'pressure',
        text: json['text'] ?? 'N/D',
        points: json['points'] ?? '+0.0',
        type: json['type'] ?? 'neutral',
      );
}

class ForecastData {
  final String giornoNome, giornoData, meteoIcon, temperaturaAvg, tempMinMax, ventoDati, pressione, umidita, mare, altaMarea, bassaMarea, alba, tramonto, finestraMattino, finestraSera;
  final double pescaScoreNumeric;
  final List<ScoreReason> pescaScoreReasons;
  final List<Map<String, dynamic>> hourlyData;
  final List<Map<String, dynamic>> weeklyData;

  ForecastData({
    required this.giornoNome, required this.giornoData, required this.meteoIcon, required this.temperaturaAvg,
    required this.tempMinMax, required this.ventoDati, required this.pressione, required this.umidita,
    required this.mare, required this.altaMarea, required this.bassaMarea, required this.alba, required this.tramonto,
    required this.finestraMattino, required this.finestraSera, required this.pescaScoreNumeric,
    required this.pescaScoreReasons, required this.hourlyData, required this.weeklyData,
  });

  // La firma del costruttore ORA è CORRETTA E DEFINITIVA: accetta due parametri.
  factory ForecastData.fromJson(Map<String, dynamic> json, List<Map<String, dynamic>> weeklyData) {
    final tempAvg = json['temperaturaAvg']?.toString() ?? 'N/D';
    final tempMin = json['temperaturaMin']?.toString() ?? '?';
    final tempMax = json['temperaturaMax']?.toString() ?? '?';
    final maree = json['maree'] ?? 'Alta: N/D | Bassa: N/D';
    final mareeParts = maree.split('|');
    final scoreData = json['pescaScoreData'] as Map<String, dynamic>? ?? {'numericScore': 0.0, 'reasons': []};
    final reasonsList = scoreData['reasons'] as List? ?? [];

    return ForecastData(
      giornoNome: json['giornoNome'] ?? 'N/D',
      giornoData: json['giornoData'] ?? 'N/D',
      meteoIcon: json['meteoIcon'] ?? '❓',
      temperaturaAvg: '$tempAvg°',
      tempMinMax: 'Max: $tempMax° Min: $tempMin°',
      ventoDati: json['ventoDati'] ?? 'N/D',
      pressione: "${json['pressione'] ?? 'N/D'} hPa ${json['trendPressione'] ?? ''}",
      umidita: '${json['umidita'] ?? 'N/D'}%',
      mare: "${json['acronimoMare'] ?? ''} ${json['temperaturaAcqua'] ?? ''}° ${json['velocitaCorrente'] ?? ''} kn",
      altaMarea: mareeParts.isNotEmpty ? mareeParts[0].replaceFirst('Alta:', '').trim() : 'N/D',
      bassaMarea: mareeParts.length > 1 ? mareeParts[1].replaceFirst('Bassa:', '').trim() : 'N/D',
      alba: (json['alba'] as String?)?.replaceFirst('☀️', '').trim() ?? 'N/D',
      tramonto: (json['tramonto'] as String?)?.trim() ?? 'N/D',
      finestraMattino: json['finestraMattino']?['orario'] ?? 'N/D',
      finestraSera: json['finestraSera']?['orario'] ?? 'N/D',
      pescaScoreNumeric: (scoreData['numericScore'] as num?)?.toDouble() ?? 0.0,
      pescaScoreReasons: reasonsList.map((r) => ScoreReason.fromJson(r)).toList(),
      hourlyData: (json['hourly'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      weeklyData: weeklyData, // Ora 'weeklyData' è correttamente definito e usato.
    );
  }

  /// Determina il path dell'immagine di sfondo corretta.

  /// Restituisce la previsione oraria più vicina al momento attuale.
  /// Utile per la card principale (Hero).
  Map<String, dynamic> get currentHourData {
    if (hourlyData.isEmpty) {
      // Fallback elegante se i dati orari non sono presenti
      return {
        'time': '--:--',
        'tempC': temperaturaAvg.replaceAll('°', ''), // Usa la temp media del giorno
        'weatherCode': '0', // Codice per 'sconosciuto'
        'isNow': true,
      };
    }

    final now = DateTime.now();
    // Trova la prima previsione oraria che è successiva all'ora attuale
    final currentHour = hourlyData.firstWhere(
      (hour) {
        final hourTime = int.tryParse(hour['time']?.split(':')[0] ?? '0') ?? 0;
        return hourTime >= now.hour;
      },
      orElse: () => hourlyData.last, // Se è tardi, usa l'ultima previsione del giorno
    );
    
    print('[ForecastData Log] Dati orari correnti trovati per le ${now.hour}:00. Usando: ${currentHour['time']}');

    return {...currentHour, 'isNow': true}; // Aggiunge un flag per la UI
  }

  /// Restituisce la lista di previsioni orarie da mostrare nella riga orizzontale.
  /// Esclude le ore già passate per una UI più pulita.
  List<Map<String, dynamic>> get hourlyForecastForDisplay {
    if (hourlyData.isEmpty) return [];

    final now = DateTime.now();
    final int currentHourInt = now.hour;
    
    // Filtra la lista per mostrare solo le ore future
    return hourlyData.where((hour) {
      final hourTime = int.tryParse(hour['time']?.split(':')[0] ?? '0') ?? 0;
      return hourTime >= currentHourInt;
    }).toList();
  }

  String get backgroundImagePath {
    try {
      DateTime _parseTime(String timeStr) {
        final now = DateTime.now();
        final parts = timeStr.split(':');
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      }

      final oraCorrente = DateTime.now();
      final oraAlba = _parseTime(alba);
      final oraTramonto = _parseTime(tramonto);

      final unOraPrimaAlba = oraAlba.subtract(const Duration(hours: 1));
      final unOraDopoAlba = oraAlba.add(const Duration(hours: 1));
      final unOraPrimaTramonto = oraTramonto.subtract(const Duration(hours: 1));
      final unOraDopoTramonto = oraTramonto.add(const Duration(hours: 1));
      
      if ((oraCorrente.isAfter(unOraPrimaAlba) && oraCorrente.isBefore(unOraDopoAlba)) ||
          (oraCorrente.isAfter(unOraPrimaTramonto) && oraCorrente.isBefore(unOraDopoTramonto))) {
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