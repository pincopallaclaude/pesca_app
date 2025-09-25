// lib/widgets/hourly_forecast.dart

import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart'; // Aggiungi import per il nuovo pacchetto di icone
import '../utils/weather_icon_mapper.dart'; // Aggiungi import per il nostro helper

class HourlyForecast extends StatelessWidget {
  final List<Map<String, dynamic>> hourlyData;

  const HourlyForecast({required this.hourlyData, super.key});

  @override
  Widget build(BuildContext context) {
    print(
        '[HourlyForecast Log] Dati ricevuti per la visualizzazione: ${hourlyData.length} elementi.');

    if (hourlyData.isEmpty) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: Text(
            'Previsioni orarie non disponibili.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          final data = hourlyData[index];
          // LA LOGICA "isNow" VIENE COMPLETAMENTE RIMOSSA
          final timeLabel = (data['time'] as String?)?.split(':')[0] ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  timeLabel, // Mostra sempre e solo l'ora
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70, // Stile unificato
                  ),
                ),
                BoxedIcon(
                  getWeatherIcon(data['weatherCode'] as String? ?? '0'),
                  size: 28,
                  color: Colors.white, // Colore unificato
                ),
                Text(
                  "${data['tempC']}°",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
