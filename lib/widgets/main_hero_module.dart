// /lib/widgets/main_hero_modul// /lib/widgets/main_hero_module.dart

import 'package:flutter/material.dart';
import '../models/forecast_data.dart';
import '../utils/weather_icon_mapper.dart';
import '../widgets/fishing_score_indicator.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/score_chart_dialog.dart';
import '../widgets/score_details_dialog.dart';
import 'package:weather_icons/weather_icons.dart';

class MainHeroModule extends StatelessWidget {
  final ForecastData data;
  final bool isSunlightModeActive;

  const MainHeroModule({
    required this.data,
    required this.isSunlightModeActive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<Shadow> sunlightTextShadows = [
      const Shadow(blurRadius: 8, color: Colors.black87, offset: Offset(0, 2)),
    ];

    final largeTextStyle = TextStyle(
      fontSize: 92,
      fontWeight: FontWeight.w200,
      height: 1.1,
      shadows: isSunlightModeActive ? sunlightTextShadows : null,
    );
    final mediumTextStyle = TextStyle(
      fontSize: 16,
      color: Colors.white70,
      fontWeight: FontWeight.w500,
      shadows: isSunlightModeActive ? sunlightTextShadows : null,
    );

    return GlassmorphismCard(
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.giornoNome.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.giornoData,
                      style:
                          const TextStyle(fontSize: 15, color: Colors.white70),
                    )
                  ],
                ),
              ),
              BoxedIcon(
                getWeatherIcon(
                  data.currentHourData['weatherCode'] as String? ?? '0',
                  isDay: data.currentHourData['isDay'] as bool? ?? false,
                ),
                size: 42,
                color: getWeatherIconColor(
                  data.currentHourData['weatherCode'] as String? ?? '0',
                  isDay: data.currentHourData['isDay'] as bool? ?? true,
                ),
              ),
            ]),
        const SizedBox(height: 8),
        Text(
            "${data.currentHourData['tempC'] ?? data.temperaturaAvg.replaceAll('°', '')}°",
            style: largeTextStyle),
        Text(data.tempMinMax, style: mediumTextStyle),
        const SizedBox(height: 12),
        IconTheme(
          data: IconThemeData(color: Colors.white.withOpacity(0.8), size: 18),
          child: DefaultTextStyle(
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(WeatherIcons.sunrise),
                const SizedBox(width: 6),
                Text(data.sunriseTime),
                const SizedBox(width: 20),
                Icon(getMoonPhaseIcon(data.moonPhase)),
                const SizedBox(width: 20),
                const Icon(WeatherIcons.sunset),
                const SizedBox(width: 6),
                Text(data.sunsetTime),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => showScoreDetailsDialog(context, data),
          child: FishingScoreIndicator(score: data.pescaScoreNumeric),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWindowItem("MATTINO", data.finestraMattino, context, data),
            Container(
                height: 30, width: 1, color: Colors.white.withOpacity(0.2)),
            _buildWindowItem("SERA", data.finestraSera, context, data),
          ],
        ),
        const Divider(color: Colors.white24, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem('Vento', data.ventoDati),
            _buildInfoItem('Mare', data.mare),
            _buildInfoItem('Umidità', data.umidita),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem('Pressione', data.pressione),
            _buildInfoItem('Alta Marea', data.altaMarea),
            _buildInfoItem('Bassa Marea', data.bassaMarea),
          ],
        ),
      ]),
    );
  }

  // [RIPRISTINATO] Metodi helper che avevo omesso per errore.
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1),
            ),
          ],
        ),
      );

  Widget _buildWindowItem(String label, String time, BuildContext context,
      ForecastData forecastData) {
    bool sconsigliato = time.toLowerCase() == 'sconsigliato' ||
        time.toLowerCase() == 'n/d' ||
        time.toLowerCase() == 'dati insuff.';
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!sconsigliato && forecastData.hourlyScores.isNotEmpty) {
            showScoreChartDialog(context, forecastData.hourlyScores);
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
