// lib/widgets/hourly_forecast.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:weather_icons/weather_icons.dart';
import '../utils/weather_icon_mapper.dart';

/// Un widget interattivo che mostra le previsioni orarie in due stati:
/// - Contratto: Mostra solo i dati essenziali (ora, icona, temperatura).
/// - Espanso: Mostra un set completo di dati meteo-marini.
class HourlyForecast extends StatefulWidget {
  final List<Map<String, dynamic>> hourlyData;

  const HourlyForecast({required this.hourlyData, super.key});

  @override
  State<HourlyForecast> createState() => _HourlyForecastState();
}

class _HourlyForecastState extends State<HourlyForecast> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.hourlyData.isEmpty) {
      return const SizedBox.shrink(); // Non mostrare nulla se non ci sono dati
    }

    // Calcoliamo dinamicamente l'altezza in base allo stato
    const double contractedHeight = 130.0;
    const double expandedHeight =
        320.0; // Altezza stimata per contenere tutti i dati

    return Column(
      children: [
        _buildHeader(),
        // Il contenitore che si anima in altezza
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: _isExpanded ? expandedHeight : contractedHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.hourlyData.length,
            itemBuilder: (context, index) {
              final data = widget.hourlyData[index];
              return _buildHourColumn(data, _isExpanded);
            },
          ),
        ),
      ],
    );
  }

  /// Costruisce l'header della sezione con il titolo e il pulsante di espansione.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "PREVISIONI NELLE PROSSIME ORE",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Costruisce la colonna per una singola ora, mostrando i dati
  /// in base allo stato `isExpanded`.
  Widget _buildHourColumn(Map<String, dynamic> data, bool isExpanded) {
    final timeLabel = (data['time'] as String?)?.split(':')[0] ?? '';

    return Container(
      width: 80, // Larghezza fissa per ogni colonna
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
            right:
                BorderSide(color: Colors.white.withOpacity(0.1), width: 1.0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // --- DATI SEMPRE VISIBILI ---
          Text(timeLabel,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const Spacer(),
          BoxedIcon(
            getWeatherIcon(
              data['weatherCode'] as String? ?? '0',
              isDay: data['isDay'] as bool? ?? true,
            ),
            size: 28,
            color: getWeatherIconColor(
              data['weatherCode'] as String? ?? '0',
              isDay: data['isDay'] as bool? ?? true,
            ),
          ),
          const Spacer(),
          Text("${data['tempC']}°",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          // --- DATI VISIBILI SOLO QUANDO ESPANSO ---
          if (isExpanded) ...[
            const Divider(color: Colors.white24, height: 24),
            _buildDetailRow(
              _buildWindIcon(data['windDirectionDegrees'] as int? ?? 0),
              '${data['windSpeedKn']} kn',
            ),
            _buildDetailRow(
                Icon(WeatherIcons.raindrop,
                    size: 16, color: Colors.cyan.shade200),
                '${data['precipitationProbability']}%'),
            _buildDetailRow(
                Icon(WeatherIcons.raindrops,
                    size: 16, color: Colors.blue.shade300),
                '${data['precipitation']} mm'),
            _buildDetailRow(
                Icon(WeatherIcons.barometer, size: 16, color: Colors.white70),
                '${data['pressure']} hPa'),
            _buildDetailRow(
                Icon(Icons.water_drop_outlined,
                    size: 16, color: Colors.blue.shade200),
                '${data['humidity']}%'),
            _buildDetailRow(
                Icon(WeatherIcons.tsunami,
                    size: 16, color: Colors.white70), // NOME ICONA CORRETTO
                '${data['waveHeight']} m'),
            _buildDetailRow(
                Icon(WeatherIcons.day_haze,
                    size: 16, color: Colors.white70), // NOME ICONA CORRETTO
                data['tide']?.toString().split(' ')[0] ??
                    '', // Solo 'Alta' o 'Bassa'
                subText:
                    data['tide']?.toString().split(' ')[1] ?? '' // Solo l'ora
                ),
          ],
        ],
      ),
    );
  }

  /// Widget helper per costruire una riga di dettaglio compatta (icona + testo).
  Widget _buildDetailRow(Widget icon, String text, {String? subText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(text, style: const TextStyle(fontSize: 12)),
            ],
          ),
          if (subText != null)
            Text(subText,
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  /// Helper per creare l'icona del vento ruotata.
  Widget _buildWindIcon(int degrees) {
    return Transform.rotate(
      angle: (degrees * math.pi / 180) + (math.pi),
      child: const Icon(Icons.navigation, color: Colors.white, size: 16),
    );
  }
}
