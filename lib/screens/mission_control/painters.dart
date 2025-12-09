import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PlasmaGraphPainter extends CustomPainter {
  final List<double> data;
  final double heightFactor;
  final double? latencyBaseline;

  PlasmaGraphPainter(
      {required this.data, this.heightFactor = 1.0, this.latencyBaseline});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final path = Path();
    final width = size.width;
    final height = size.height * heightFactor;
    final step = width / (data.length - 1).clamp(1, double.infinity);

    // Banda di confidenza (Baseline)
    if (latencyBaseline != null) {
      final baselineY = size.height - (latencyBaseline! / 100 * height);
      final upperY = size.height - ((latencyBaseline! + 10).clamp(0, 100) / 100 * height);
      final lowerY = size.height - ((latencyBaseline! - 10).clamp(0, 100) / 100 * height);

      final rect = Rect.fromLTRB(0, upperY, width, lowerY);
      final paintRect = Paint()..color = Colors.blueGrey.withValues(alpha: 0.1);
      canvas.drawRect(rect, paintRect);

      final paintLine = Paint()
        ..color = Colors.blueGrey.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, baselineY), Offset(width, baselineY), paintLine);
    }

    path.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      double x = i * step;
      double y = size.height - (data[i] / 100 * height);
      if (i == 0)
        path.lineTo(x, y);
      else {
        double prevX = (i - 1) * step;
        double prevY = size.height - (data[i - 1] / 100 * height);
        double cX = (prevX + x) / 2;
        path.cubicTo(cX, prevY, cX, y, x, y);
      }
    }
    path.lineTo(width, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.greenAccent.withValues(alpha: 0.4),
          Colors.blueAccent.withValues(alpha: 0.0)
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, size.height));

    // Griglia retrostante
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    for (double i = 0; i < width; i += 20)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 15)
      canvas.drawLine(Offset(0, i), Offset(width, i), gridPaint);

    canvas.drawPath(path, paint);

    // Linea superiore neon
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      double x = i * step;
      double y = size.height - (data[i] / 100 * height);
      if (i == 0)
        linePath.moveTo(x, y);
      else {
        double prevX = (i - 1) * step;
        double prevY = size.height - (data[i - 1] / 100 * height);
        double cX = (prevX + x) / 2;
        linePath.cubicTo(cX, prevY, cX, y, x, y);
      }
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(ui.BlurStyle.solid, 1.5));

    // Punti dati
    for (int i = 0; i < data.length; i += 5) {
      double x = i * step;
      double y = size.height - (data[i] / 100 * height);
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double i = 0; i < size.width; i += step)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += step)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
