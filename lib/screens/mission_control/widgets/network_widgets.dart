import 'package:flutter/material.dart';

Widget buildNetworkDiagnosticRow({required String label, required String value, required Color color}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
      Text(value,
          style: TextStyle(
              color: color, fontSize: 9, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
    ],
  );
}

Widget buildNetworkIODetail(String label, String value, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
      Text(value,
          style: TextStyle(
              color: color, fontSize: 9, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
    ],
  );
}

Widget buildThroughput(double tx, double rx) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text("TX: \ MB/s",
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 9, fontFamily: 'Courier')),
        ],
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text("RX: \ MB/s",
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontFamily: 'Courier')),
        ],
      ),
    ],
  );
}
