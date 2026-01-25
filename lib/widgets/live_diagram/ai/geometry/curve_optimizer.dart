// /lib/widgets/live_diagram/ai/geometry/curve_optimizer.dart

import 'dart:math';
import 'package:flutter/material.dart';

/// Ottimizzatore geometrico per curve Bézier.
/// Implementa algoritmi per minimizzare crossing e ottimizzare curvatura.
class CurveOptimizer {
  /// Ottimizza un set di curve Bézier per minimizzare intersezioni
  static List<BezierCurve> optimizeCurves(
    List<BezierCurve> curves, {
    int maxIterations = 50,
  }) {
    var optimized = List<BezierCurve>.from(curves);

    for (int iter = 0; iter < maxIterations; iter++) {
      bool improved = false;

      for (int i = 0; i < optimized.length; i++) {
        final current = optimized[i];
        final alternative = _generateAlternativeCurve(current);

        // Calcola crossing count per entrambe
        final currentCrossings = _countCrossings(current, optimized, i);
        final altCrossings = _countCrossings(alternative, optimized, i);

        if (altCrossings < currentCrossings) {
          optimized[i] = alternative;
          improved = true;
        }
      }

      if (!improved) break; // Convergenza raggiunta
    }

    return optimized;
  }

  /// Calcola il crossing number totale per un set di curve
  static int calculateCrossingNumber(List<BezierCurve> curves) {
    int count = 0;

    for (int i = 0; i < curves.length; i++) {
      for (int j = i + 1; j < curves.length; j++) {
        if (curvesIntersect(curves[i], curves[j])) {
          count++;
        }
      }
    }

    return count;
  }

  /// Check intersezione tra due curve Bézier quadratiche
  static bool curvesIntersect(BezierCurve a, BezierCurve b) {
    // Sampling-based check (per semplicità, no analitico)
    const samples = 20;

    for (int i = 0; i <= samples; i++) {
      final t1 = i / samples;
      final p1 = a.pointAt(t1);

      for (int j = 0; j <= samples; j++) {
        final t2 = j / samples;
        final p2 = b.pointAt(t2);

        if ((p1 - p2).distance < 0.02) {
          // Threshold 2%
          return true;
        }
      }
    }

    return false;
  }

  /// Calcola uniformità di curvatura per una curva
  static double calculateCurvatureUniformity(BezierCurve curve) {
    const samples = 10;
    final curvatures = <double>[];

    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      curvatures.add(_curvatureAt(curve, t));
    }

    final mean = curvatures.reduce((a, b) => a + b) / curvatures.length;
    final variance =
        curvatures.map((c) => pow(c - mean, 2)).reduce((a, b) => a + b) /
            curvatures.length;

    return 1.0 - (sqrt(variance) / (mean + 1e-6)).clamp(0.0, 1.0);
  }

  /// Genera una curva alternativa con control point variato
  static BezierCurve _generateAlternativeCurve(BezierCurve original) {
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final magnitude = 20 + random.nextDouble() * 40;

    final newControl = original.control +
        Offset(
          cos(angle) * magnitude,
          sin(angle) * magnitude,
        );

    return BezierCurve(
      start: original.start,
      control: newControl,
      end: original.end,
    );
  }

  /// Conta crossing di una curva con tutte le altre
  static int _countCrossings(
    BezierCurve curve,
    List<BezierCurve> allCurves,
    int skipIndex,
  ) {
    int count = 0;

    for (int i = 0; i < allCurves.length; i++) {
      if (i != skipIndex && curvesIntersect(curve, allCurves[i])) {
        count++;
      }
    }

    return count;
  }

  /// Calcola curvatura locale in punto t
  static double _curvatureAt(BezierCurve curve, double t) {
    // Derivate prima e seconda
    final d1 = curve.derivativeAt(t);
    final d2 = curve.secondDerivativeAt(t);

    final cross = d1.dx * d2.dy - d1.dy * d2.dx;
    final speed = sqrt(d1.dx * d1.dx + d1.dy * d1.dy);

    return cross / (pow(speed, 3) + 1e-6);
  }

  /// Ottimizza control point per minimizzare curvatura massima
  static BezierCurve optimizeForSmoothness(BezierCurve curve) {
    var best = curve;
    var bestMaxCurvature = _maxCurvature(curve);

    // Prova variazioni del control point
    for (int angle = 0; angle < 360; angle += 15) {
      for (double radius = 20; radius <= 80; radius += 10) {
        final radians = angle * pi / 180;
        final testControl = curve.control +
            Offset(
              cos(radians) * radius,
              sin(radians) * radius,
            );

        final testCurve = BezierCurve(
          start: curve.start,
          control: testControl,
          end: curve.end,
        );

        final maxCurv = _maxCurvature(testCurve);
        if (maxCurv < bestMaxCurvature) {
          best = testCurve;
          bestMaxCurvature = maxCurv;
        }
      }
    }

    return best;
  }

  /// Calcola curvatura massima lungo la curva
  static double _maxCurvature(BezierCurve curve) {
    const samples = 20;
    double maxCurv = 0.0;

    for (int i = 0; i <= samples; i++) {
      final curv = _curvatureAt(curve, i / samples).abs();
      if (curv > maxCurv) maxCurv = curv;
    }

    return maxCurv;
  }
}

/// Rappresentazione curva Bézier quadratica
class BezierCurve {
  final Offset start;
  final Offset control;
  final Offset end;

  BezierCurve({
    required this.start,
    required this.control,
    required this.end,
  });

  /// Calcola punto sulla curva al parametro t [0,1]
  Offset pointAt(double t) {
    final u = 1 - t;
    return start * (u * u) + control * (2 * u * t) + end * (t * t);
  }

  /// Derivata prima al parametro t
  Offset derivativeAt(double t) {
    return (control - start) * (2 * (1 - t)) + (end - control) * (2 * t);
  }

  /// Derivata seconda (costante per quadratiche)
  Offset secondDerivativeAt(double t) {
    return (end - control * 2.0 + start) * 2.0;
  }

  /// Lunghezza approssimata della curva
  double get length {
    const samples = 20;
    double len = 0.0;

    for (int i = 0; i < samples; i++) {
      final p1 = pointAt(i / samples);
      final p2 = pointAt((i + 1) / samples);
      len += (p2 - p1).distance;
    }

    return len;
  }

  /// Bounding box della curva
  Rect get bounds {
    final points = [start, control, end];
    final xs = points.map((p) => p.dx);
    final ys = points.map((p) => p.dy);

    return Rect.fromLTRB(
      xs.reduce(min),
      ys.reduce(min),
      xs.reduce(max),
      ys.reduce(max),
    );
  }
}
