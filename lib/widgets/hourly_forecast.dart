import 'package:flutter/material.dart';
import '../widgets/glassmorphism_card.dart'; // Potrebbe essere usata se non è un child di un'altra card
import 'package:cached_network_image/cached_network_image.dart'; // Aggiungi l'import

class HourlyForecast extends StatelessWidget {
  final List<Map<String, dynamic>> hourlyData;

  const HourlyForecast({required this.hourlyData, super.key});

  @override
  Widget build(BuildContext context) {
    print('[HourlyForecast Log] Dati ricevuti per la visualizzazione: ${hourlyData.length} elementi.');

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
    
    // La prima ora nella lista è quella "attuale"
    final currentHour = hourlyData[0]; 

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          final data = hourlyData[index];
          // Il flag 'isNow' ci aiuta a determinare l'ora corrente
          final isNow = data['time'] == currentHour['time'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  isNow ? 'Adesso' : (data['time'] as String?)?.split(':')[0] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isNow ? Colors.white : Colors.white70,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CachedNetworkImage(
                    imageUrl: data['weatherIconUrl'] as String? ?? '',
                    placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                    errorWidget: (context, url, error) => Icon(
                      Icons.cloud_off, 
                      color: Colors.white.withOpacity(0.5), 
                      size: 28,
                    ),
                    color: isNow ? Colors.yellow.shade600 : Colors.white,
                  ),
                ),
                Text(
                  "${data['tempC']}°",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}