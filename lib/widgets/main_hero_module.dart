// lib/widgets/main_hero_module.dart

import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import '../models/forecast_data.dart';
import '../utils/weather_icon_mapper.dart';
import 'fishing_score_indicator.dart';
import 'glassmorphism_card.dart';
import 'score_chart_dialog.dart';
import 'score_details_dialog.dart';
import 'feedback_dialog.dart'; // NUOVO: Importa il dialogo di feedback
import '../services/api_service.dart'; // NUOVO: Importa il servizio API

// Internal widget for the pulsing icon. This remains as our final refined version.
class _PulsingIcon extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingIcon({required this.onTap});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withOpacity(0.85),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// [FINAL VERSION] Correctly defined as StatelessWidget.
// State management is now correctly handled by the parent screen.
class MainHeroModule extends StatelessWidget {
  final ForecastData data;
  final bool isSunlightModeActive;
  final VoidCallback
      onAnalysisTap; // [CORRECT] The callback parameter is correctly defined here.

  const MainHeroModule({
    super.key,
    required this.data,
    required this.isSunlightModeActive,
    required this.onAnalysisTap, // And it's required in the constructor.
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
        shadows: isSunlightModeActive ? sunlightTextShadows : null);
    final mediumTextStyle = TextStyle(
        fontSize: 16,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
        shadows: isSunlightModeActive ? sunlightTextShadows : null);

    return GlassmorphismCard(
      child: Column(children: [
        // All the existing UI content remains the same
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
                    Text(data.giornoNome.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    Text(data.giornoData,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),
              BoxedIcon(
                getWeatherIcon(
                    data.currentHourData['weatherCode'] as String? ?? '0',
                    isDay: data.currentHourData['isDay'] as bool? ?? false),
                size: 42,
                color: getWeatherIconColor(
                    data.currentHourData['weatherCode'] as String? ?? '0',
                    isDay: data.currentHourData['isDay'] as bool? ?? true),
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
        SizedBox(
          width: 200,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => showScoreDetailsDialog(context, data),
                child: FishingScoreIndicator(score: data.pescaScoreNumeric),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: _PulsingIcon(onTap: onAnalysisTap),
              ),
              // --- INIZIO BLOCCO CORRETTO ---
              Positioned(
                top: -2,
                left: -5,
                child: InkWell(
                  onTap: () {
                    // I dati meteo e di location non sono disponibili direttamente nel modello `ForecastData`
                    // che hai condiviso, quindi li ricostruiamo. Per il futuro, sarebbe
                    // meglio aggiungerli direttamente al modello.
                    // Per ora, usiamo i dati disponibili.

                    // NOTA: 'analysisText' non è presente in ForecastData.
                    // Per ora, passeremo una stringa vuota come placeholder.
                    // Questo dovrà essere risolto passando l'analisi al widget.
                    final String analysisTextPlaceholder =
                        "Analisi non disponibile in questo contesto.";

                    showDialog(
                      context: context,
                      builder: (context) => FeedbackDialog(
                        // Forniamo i parametri richiesti dal costruttore
                        sessionId: data.sessionId,
                        location: {
                          // Ricostruiamo la mappa location
                          'name': data.giornoNome,
                          // Lat/Lon non sono nel modello, usiamo valori placeholder
                          'lat': 0.0,
                          'lon': 0.0,
                        },
                        weatherData: {
                          // Ricostruiamo una mappa base dei dati meteo
                          'tempMin': data.temperaturaMin,
                          'tempMax': data.temperaturaMax,
                          'weatherCode': data.dailyWeatherCode,
                          'windSpeed': data.dailyWindSpeedKn,
                          'pressure': data.dailyPressure,
                        },

                        pescaScore: data.pescaScoreNumeric,
                        aiAnalysis: analysisTextPlaceholder,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.feedback_outlined,
                      color: Colors.white.withOpacity(0.75),
                      size: 18,
                    ),
                  ),
                ),
              ),
              // --- FINE BLOCCO CORRETTO ---
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildWindowItem("MATTINO", data.finestraMattino, context, data),
          Container(height: 30, width: 1, color: Colors.white.withOpacity(0.2)),
          _buildWindowItem("SERA", data.finestraSera, context, data),
        ]),
        const Divider(color: Colors.white24, height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildInfoItem('Vento', data.ventoDati),
          _buildInfoItem('Mare', data.mare),
          _buildInfoItem('Umidità', data.umidita),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildInfoItem('Pressione', data.pressione),
          _buildInfoItem('Alta Marea', data.altaMarea),
          _buildInfoItem('Bassa Marea', data.bassaMarea),
        ]),
      ]),
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
