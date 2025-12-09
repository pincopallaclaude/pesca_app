// /lib/widgets/premium_drawer_painters.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

// Estensione per gestire l'opacità
extension ColorAlpha on Color {
  Color withValues({double alpha = 1.0}) {
    return this.withOpacity(alpha.clamp(0.0, 1.0));
  }
}

// --- PAINTER PER BACKGROUND ANIMATO ---
class MeshGradientPainter extends CustomPainter {
  final double animation;

  MeshGradientPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    _drawGradientBackground(canvas, size);
    _drawGridLines(canvas, size);
  }

  void _drawGradientBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      colors: [
        Colors.blueAccent.withValues(alpha: 0.05),
        Colors.purpleAccent.withValues(alpha: 0.03),
        Colors.cyanAccent.withValues(alpha: 0.05),
      ],
      stops: [
        0.0,
        0.5 + 0.2 * math.sin(animation * 2 * math.pi),
        1.0,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.01)
      ..strokeWidth = 1;

    // Linee verticali
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }

    // Linee orizzontali
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) => true;
}
