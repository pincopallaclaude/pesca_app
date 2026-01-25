import 'dart:math';
import 'package:flutter/material.dart';

class GeometryEngine {
  static Map<String, Offset> arrangeSatellites(List<String> satellites, {required Offset center, required double radius, required double verticalOffset}) {
    final positions = <String, Offset>{};
    final double angleStep = (2 * pi) / (satellites.isEmpty ? 1 : satellites.length);
    double currentAngle = -pi / 2;
    for (int i = 0; i < satellites.length; i++) {
      final x = center.dx + cos(currentAngle) * (radius * 1.5);
      final y = center.dy + sin(currentAngle) * radius;
      positions[satellites[i]] = Offset(x.clamp(0.10, 0.90), y.clamp(0.10, 0.90));
      currentAngle += angleStep;
    }
    return positions;
  }

  static Offset calculateAdaptiveControlPoint(String from, String to, Map<String, Offset> positions) {
    final p1 = positions[from]; final p2 = positions[to];
    if (p1 == null || p2 == null) return const Offset(40.0, -30.0);
    final dx = p2.dx - p1.dx; final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < 0.05) return const Offset(60.0, -40.0);
    Offset cp;
    if (dx.abs() < 0.1) { cp = Offset(dy.sign * distance * 300, 0); }
    else if (dy.abs() < 0.1) { cp = Offset(0, -dx.sign * distance * 300); }
    else { cp = Offset(-dy * distance * 250, dx * distance * 250); }
    return cp.distance > 300 ? (cp / cp.distance) * 300 : cp;
  }
}
