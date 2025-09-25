import 'package:flutter/material.dart';
import '../widgets/glassmorphism_card.dart'; // Potrebbe essere usata se non è un child di un'altra card

class WeeklyForecast extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const WeeklyForecast({required this.weeklyData, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children:
            weeklyData.map((data) => _buildWeeklyRow(context, data)).toList());
  }

  Widget _buildWeeklyRow(BuildContext context, Map<String, dynamic> data) {
    // Estrai i dati con un cast sicuro
    final dayName = data['day'] as String? ?? 'N/D';
    final icon = data['icon'] as IconData? ?? Icons.help_outline;
    final iconColor = data['icon_color'] as Color? ?? Colors.white;

    // --- CORREZIONE DEFINITIVA QUI ---
    // Leggiamo i valori come 'num' generico per accettare sia int che double,
    // poi li arrotondiamo a 'int' per la UI.
    final minTemp = (data['min'] as num?)?.round() ?? 0;
    final maxTemp = (data['max'] as num?)?.round() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(dayName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Icon(icon, color: iconColor, size: 28)),
          Expanded(
              flex: 2,
              child: Text("$minTemp°",
                  style: const TextStyle(fontSize: 18, color: Colors.white70))),
          Expanded(flex: 5, child: _buildTempBar(minTemp, maxTemp)),
          Expanded(
              flex: 2,
              child: Text("$maxTemp°",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)))
        ],
      ),
    );
  }

  Widget _buildTempBar(int min, int max) {
    const double totalMin = 10, totalMax = 35, totalRange = totalMax - totalMin;
    double startFraction = (min - totalMin) / totalRange;
    double widthFraction = (max - min) / totalRange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 1.0,
            child: Container(
              margin:
                  EdgeInsets.only(left: 100 * startFraction.clamp(0.0, 1.0)),
              width: 100 * widthFraction.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.5),
                gradient: const LinearGradient(
                    colors: [Colors.cyan, Colors.yellow, Colors.orange]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
