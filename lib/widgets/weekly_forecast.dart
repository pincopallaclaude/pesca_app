import 'package:flutter/material.dart';
import 'dart:math' as math; // Import per la rotazione (pi)
import '../models/forecast_data.dart';
import '../utils/weather_icon_mapper.dart';
import 'glassmorphism_card.dart';
import 'package:weather_icons/weather_icons.dart';

/// Un widget che mostra le previsioni settimanali in una tabella dati
/// scrollabile orizzontalmente, progettata per la massima densità di informazioni ("Power User").
class WeeklyForecast extends StatelessWidget {
  final List<ForecastData> forecastData;

  const WeeklyForecast({super.key, required this.forecastData});

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              "PREVISIONI A 7 GIORNI",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // ScrollView per permettere lo scorrimento orizzontale dei dati
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: forecastData
                  .map((dayData) => _buildForecastRow(context, dayData))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisce una singola riga della tabella delle previsioni, ora compatta e ricca di icone.
  Widget _buildForecastRow(BuildContext context, ForecastData data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(
            Text(data.giornoNome.toUpperCase()),
            width: 55,
          ),
          _buildTableCell(
            _buildScoreCell(
                data.pescaScoreNumeric.round()), // Nuovo widget compatto
            width: 60,
          ),
          _buildTableCell(
            BoxedIcon(
              getWeatherIcon(data.dailyWeatherCode, isDay: true),
              color: getWeatherIconColor(data.dailyWeatherCode, isDay: true),
              size: 28,
            ),
            width: 45,
          ),
          _buildTableCell(
            _buildTempCell(data.temperaturaMax,
                data.temperaturaMin), // Nuovo widget compatto
            width: 45,
          ),
          _buildTableCell(
            _buildWindCell(data.dailyWindSpeedKn,
                data.dailyWindDirectionDegrees), // Nuovo widget compatto
            width: 70,
          ),
          _buildTableCell(
            _buildHumidityCell(data.dailyHumidity), // Nuovo widget compatto
            width: 70,
          ),
          _buildTableCell(
            _buildPressureCell(data.dailyPressure,
                data.trendPressione), // Nuovo widget compatto
            width: 90,
          ),
        ],
      ),
    );
  }

  // --- NUOVI WIDGET "HELPER" PER LE CELLE COMPATTE ---

  Widget _buildScoreCell(int score) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phishing, color: Colors.cyan, size: 20),
          const SizedBox(width: 6),
          Text(score.toString(),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildTempCell(double max, double min) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("${max.round()}°",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text("${min.round()}°",
              style: const TextStyle(color: Colors.white70)),
        ],
      );

  Widget _buildWindCell(int speed, int degrees) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // L'icona viene ruotata in base ai gradi forniti dal backend
          Transform.rotate(
            angle: (degrees * math.pi / 180) +
                (math
                    .pi), // Aggiungiamo 180° (pi) perché l'icona 'navigation' punta in su di default
            child: const Icon(Icons.navigation, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 5),
          Text("$speed kn",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildHumidityCell(int humidity) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_outlined,
              color: Colors.blue.shade200, size: 18),
          const SizedBox(width: 5),
          Text("$humidity%",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildPressureCell(int pressure, String trend) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$pressure hPa",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          _getPressureTrendIcon(trend),
        ],
      );

  /// Widget helper per creare una "cella" della tabella con una larghezza fissa.
  Widget _buildTableCell(Widget child, {required double width}) {
    return SizedBox(
      width: width,
      child: Center(child: child),
    );
  }

  /// Helper per mappare il carattere del trend di pressione a un'icona.
  Widget _getPressureTrendIcon(String trend) {
    switch (trend) {
      case '↑':
        return const Icon(Icons.arrow_upward, color: Colors.white70, size: 20);
      case '↓':
        return const Icon(Icons.arrow_downward, color: Colors.cyan, size: 20);
      default:
        return const Icon(Icons.arrow_forward, color: Colors.white70, size: 20);
    }
  }
}
