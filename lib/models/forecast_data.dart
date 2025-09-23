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

  factory ForecastData.fromJson(Map<String, dynamic> json) {
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
      hourlyData: mockHourlyData, // Dati fittizi come nell'originale
      weeklyData: mockWeeklyData, // Dati fittizi come nell'originale
    );
  }
  /// Determina il path dell'immagine di sfondo corretta in base all'orario
  /// e alle condizioni meteo del giorno corrente.
  String get backgroundImagePath {
    try {
      // 1. Helper per convertire stringhe HH:mm in oggetti DateTime completi.
      DateTime _parseTime(String timeStr) {
        final now = DateTime.now();
        final parts = timeStr.split(':');
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      }

      final oraCorrente = DateTime.now();
      final oraAlba = _parseTime(alba);
      final oraTramonto = _parseTime(tramonto);

      // 2. REGOLA 1: Finestra "Golden Hour" (Alba/Tramonto)
      final unOraPrimaAlba = oraAlba.subtract(const Duration(hours: 1));
      final unOraDopoAlba = oraAlba.add(const Duration(hours: 1));
      final unOraPrimaTramonto = oraTramonto.subtract(const Duration(hours: 1));
      final unOraDopoTramonto = oraTramonto.add(const Duration(hours: 1));
      
      if ((oraCorrente.isAfter(unOraPrimaAlba) && oraCorrente.isBefore(unOraDopoAlba)) ||
          (oraCorrente.isAfter(unOraPrimaTramonto) && oraCorrente.isBefore(unOraDopoTramonto))) {
        return 'assets/background_sunset.jpg';
      }

      // 3. REGOLA 2: Notte
      if (oraCorrente.isBefore(oraAlba) || oraCorrente.isAfter(oraTramonto)) {
        return 'assets/background_nocturnal.jpg';
      }

      // 4. REGOLA 3: Giorno con pioggia
      // NOTA: Qui si assume una convenzione per l'icona meteo. Adattare se necessario.
      // Questa logica cerca parole chiave generiche associate alla pioggia.
      final condizioneMeteo = meteoIcon.toLowerCase();
      if (condizioneMeteo.contains('rain') || 
          condizioneMeteo.contains('shower') ||
          condizioneMeteo.contains('thunder') ||
          condizioneMeteo.contains('pioggia') ||
          condizioneMeteo.contains('temporale')) {
        return 'assets/background_rainy.jpg';
      }

      // 5. REGOLA 4 (DEFAULT): Giorno standard
      return 'assets/background_daily.jpg';

    } catch (e) {
      // In caso di qualsiasi errore (es. parsing delle date), ritorna lo sfondo di default.
      print("Errore nel determinare lo sfondo: $e");
      return 'assets/background_daily.jpg';
    }
  }

}

// Dati fittizi presenti nel file originale
final List<Map<String, dynamic>> mockHourlyData = [
  {'time': 'Adesso', 'icon': Icons.cloud, 'temp': '23°'},
  {'time': '15:00', 'icon': Icons.wb_sunny, 'temp': '24°'}
];
final List<Map<String, dynamic>> mockWeeklyData = [
  {'day': 'Oggi', 'icon': Icons.wb_cloudy, 'icon_color': Colors.white, 'min': 21, 'max': 25},
  {'day': 'Mer', 'icon': Icons.wb_sunny, 'icon_color': Colors.yellow, 'min': 20, 'max': 24}
];