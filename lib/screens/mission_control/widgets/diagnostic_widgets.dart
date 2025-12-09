import 'package:flutter/material.dart';
import '../painters.dart';

Widget buildThreatGaugeContent(
    double score, double threatBaseline, List<double> latencyHistory) {
  Color color = score < 30
      ? Colors.greenAccent
      : score < 70
          ? Colors.orangeAccent
          : Colors.redAccent;

  final trendValue = (score - (threatBaseline + 10)).clamp(-5.0, 5.0);
  final isRising = trendValue > 0.5;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // HEADER
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("THREAT SCORE",
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(isRising ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isRising ? Colors.redAccent : Colors.greenAccent,
                  size: 10),
              const SizedBox(width: 4),
              Text(trendValue.abs().toStringAsFixed(1),
                  style: TextStyle(
                      color: isRising ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 9,
                      fontFamily: 'Courier')),
            ],
          ),
        ],
      ),

      // GAUGE CENTRALE (RIDIMENSIONATO CORRETTAMENTE)
      Expanded(
        child: Center(
          child: SizedBox(
            width: 80, // RIDOTTO DA 100 A 80
            height: 80, // RIDOTTO DA 100 A 80
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8, // RIDOTTO DA 10 A 8
                    backgroundColor: Colors.white10,
                    color: color,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(score.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20, // RIDOTTO DA 22 A 20
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier')),
                    Text(score < 30 ? "LOW" : "HIGH",
                        style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),

      // FOOTER
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("BASELINE",
                  style: TextStyle(color: Colors.white54, fontSize: 8)),
              Text(threatBaseline.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontFamily: 'Courier')),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 10,
            child: CustomPaint(
                painter: PlasmaGraphPainter(
                    data: latencyHistory.sublist(latencyHistory.length > 10
                        ? latencyHistory.length - 10
                        : 0),
                    heightFactor: 0.8)),
          ),
        ],
      ),
    ],
  );
}

Widget buildResourceRowContent(
    String label,
    double value,
    Color color,
    double cpuTimeToSaturation,
    double memTimeToSaturation,
    BuildContext context) {
  final criticalThreshold = 85.0;
  final isCritical = value >= criticalThreshold;
  final displayColor = isCritical ? Colors.redAccent : color;

  double tts = label == "CPU LOAD" ? cpuTimeToSaturation : memTimeToSaturation;
  String ttsString = tts < 1.0 ? "<1 HR" : "\ HRS";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          Text("\%",
              style: TextStyle(
                  color: displayColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 4),
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.white10,
                color: displayColor,
                minHeight: 4),
          ),
          Positioned(
            left: (criticalThreshold / 100) *
                    MediaQuery.of(context).size.width /
                    2 -
                2,
            top: 0,
            bottom: 0,
            child:
                Container(width: 1, color: Colors.white.withValues(alpha: 0.4)),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TTS PREDICT",
              style: TextStyle(color: Colors.white54, fontSize: 8)),
          Text(ttsString,
              style: TextStyle(
                  color: displayColor,
                  fontSize: 9,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ],
  );
}
