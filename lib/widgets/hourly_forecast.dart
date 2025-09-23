import 'package:flutter/material.dart';
import '../widgets/glassmorphism_card.dart'; // Potrebbe essere usata se non è un child di un'altra card

class HourlyForecast extends StatelessWidget {
  final List<Map<String, dynamic>> hourlyData;

  const HourlyForecast({required this.hourlyData, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          final data = hourlyData[index];
          bool isNow = index == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  data['time']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isNow ? Colors.white : Colors.white70,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Icon(
                  data['icon'],
                  color: isNow ? Colors.yellow.shade600 : Colors.white,
                  size: 28,
                ),
                Text(
                  data['temp']!,
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