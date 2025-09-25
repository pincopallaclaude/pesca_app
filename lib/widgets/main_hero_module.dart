// lib/widgets/main_hero_module.dart

import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import '../models/forecast_data.dart';
import '../widgets/fishing_score_indicator.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/score_details_dialog.dart';
import '../widgets/score_chart_dialog.dart'; // Importa il nuovo dialogo
import '../utils/weather_icon_mapper.dart';

class MainHeroModule extends StatelessWidget {
  final ForecastData data;

  const MainHeroModule({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.giornoNome.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                  Text(
                    data.giornoData,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  )
                ],
              ),
              BoxedIcon(
                getWeatherIcon(
                    data.currentHourData['weatherCode'] as String? ?? '0'),
                size: 42,
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              "${data.currentHourData['tempC'] ?? data.temperaturaAvg.replaceAll('°', '')}°",
              style: const TextStyle(
                  fontSize: 92, fontWeight: FontWeight.w200, height: 1.1)),
          Text(data.tempMinMax,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          GestureDetector(
            onLongPress: () =>
                showScoreDetailsDialog(context, data.pescaScoreReasons),
            child: FishingScoreIndicator(score: data.pescaScoreNumeric),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWindowItem(
                  "MATTINO", data.finestraMattino, context, data.hourlyScores),
              Container(
                  height: 30, width: 1, color: Colors.white.withOpacity(0.2)),
              _buildWindowItem(
                  "SERA", data.finestraSera, context, data.hourlyScores),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Vento', data.ventoDati),
              _buildInfoItem('Mare', data.mare),
              _buildInfoItem('Umidità', data.umidita)
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Pressione', data.pressione),
              _buildInfoItem('Alta Marea', data.altaMarea),
              _buildInfoItem('Bassa Marea', data.bassaMarea)
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)
          ],
        ),
      );

  Widget _buildWindowItem(String label, String time, BuildContext context,
      List<Map<String, dynamic>> scores) {
    bool sconsigliato = time.toLowerCase() == 'sconsigliato' ||
        time.toLowerCase() == 'dati insuff.';
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!sconsigliato) {
            print(
                '[MainHeroModule Log] Tap su finestra di pesca. Mostro il grafico.');
            showScoreChartDialog(context, scores);
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.cyan[200],
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(time,
                  style: TextStyle(
                      fontSize: sconsigliato ? 14 : 16,
                      fontWeight:
                          sconsigliato ? FontWeight.normal : FontWeight.bold,
                      color: sconsigliato ? Colors.white70 : Colors.white))
            ],
          ),
        ),
      ),
    );
  }
}
