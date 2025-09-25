// /lib/widgets/score_chart_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'glassmorphism_card.dart';

/// Funzione helper per mostrare il dialogo del grafico.
void showScoreChartDialog(
    BuildContext context, List<Map<String, dynamic>> hourlyScores) {
  print(
      '[showScoreChartDialog Log] Apro il grafico con ${hourlyScores.length} punti dati.');

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Score Chart Dialog',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) =>
        ScoreChartDialog(hourlyScores: hourlyScores),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

class ScoreChartDialog extends StatelessWidget {
  final List<Map<String, dynamic>> hourlyScores;

  const ScoreChartDialog({required this.hourlyScores, super.key});

  @override
  Widget build(BuildContext context) {
    // Trasformiamo i dati grezzi in punti per il grafico
    final List<FlSpot> spots = hourlyScores
        .map((data) {
          // Log di debug per vedere i dati esatti
          print("[ScoreChartDialog DEBUG] Processing data point: $data");

          final hour = double.tryParse(
                  (data['time'] as String?)?.split(':')[0] ?? '-1') ??
              -1.0;
          // ACCETTA QUALSIASI TIPO DI NUMERO (int, double, etc)
          final score = (data['score'] as num?)?.toDouble() ?? 0.0;

          if (hour == -1.0) {
            print(
                "[ScoreChartDialog ERROR] Failed to parse hour from time: ${data['time']}");
          }

          return FlSpot(hour, score);
        })
        .where((spot) => spot.x >= 0)
        .toList(); // Filtra i punti con ora non valida

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: GlassmorphismCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Andamento Potenziale Pesca',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 24),
              // Grafico
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval:
                          1, // Una linea orizzontale per ogni punto di score
                      verticalInterval: 1, // Una linea verticale per OGNI ORA
                      getDrawingHorizontalLine: (value) =>
                          const FlLine(color: Colors.white10, strokeWidth: 1),
                      getDrawingVerticalLine: (value) =>
                          const FlLine(color: Colors.white10, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval:
                              4, // MANTENIAMO UN INTERVALLO LEGGIBILE PER LE ETICHETTE
                          getTitlesWidget: (value, meta) {
                            if (value >= 24) return const SizedBox.shrink();
                            // Mostra l'etichetta solo per gli intervalli desiderati
                            if (value % 4 != 0) return const SizedBox.shrink();
                            return Text(
                              '${value.toInt()}h',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0, maxX: 23,
                    minY: 1, maxY: 6, // Leggero padding sopra il 5
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF66CCCC), Colors.cyanAccent],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.withOpacity(0.3),
                              Colors.cyan.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                child: const Text('Chiudi',
                    style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
