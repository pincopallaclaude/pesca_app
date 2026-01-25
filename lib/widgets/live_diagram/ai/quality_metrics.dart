// /lib/widgets/live_diagram/ai/quality_metrics.dart

import 'dart:math';
import 'package:flutter/material.dart';

/// Sistema di scoring composito per valutare la qualità di un layout.
/// Combina metriche geometriche, percettive e semantiche.
class QualityMetrics {
  final double crossingNumber; // 0-1 (0 = nessun crossing, 1 = molti)
  final double segmentUniformity; // 0-1 (1 = lunghezze uniformi)
  final double spatialBalance; // 0-1 (1 = distribuzione ottimale)
  final double edgeAngleVariance; // 0-1 (1 = direzioni variate)
  final double nodeSeparation; // 0-1 (1 = spaziatura ottimale)

  const QualityMetrics({
    required this.crossingNumber,
    required this.segmentUniformity,
    required this.spatialBalance,
    required this.edgeAngleVariance,
    required this.nodeSeparation,
  });

  /// Score composito pesato (0-1, higher is better)
  double get compositeScore {
    return (1.0 - crossingNumber) * 0.35 + // Priorità massima: no overlaps
        segmentUniformity * 0.25 + // Leggibilità visiva
        spatialBalance * 0.20 + // Distribuzione armoniosa
        edgeAngleVariance * 0.10 + // Variety direzionale
        nodeSeparation * 0.10; // Spazio sufficiente
  }

  /// Classificazione qualitativa
  String get grade {
    if (compositeScore >= 0.85) return 'EXCELLENT';
    if (compositeScore >= 0.70) return 'GOOD';
    if (compositeScore >= 0.55) return 'ACCEPTABLE';
    return 'POOR';
  }

  @override
  String toString() {
    return '''
=== QUALITY METRICS ===
Composite Score: ${(compositeScore * 100).toStringAsFixed(1)}% ($grade)

Breakdown:
  • Crossing Number:     ${(crossingNumber * 100).toStringAsFixed(1)}%
  • Segment Uniformity:  ${(segmentUniformity * 100).toStringAsFixed(1)}%
  • Spatial Balance:     ${(spatialBalance * 100).toStringAsFixed(1)}%
  • Edge Angle Variance: ${(edgeAngleVariance * 100).toStringAsFixed(1)}%
  • Node Separation:     ${(nodeSeparation * 100).toStringAsFixed(1)}%
''';
  }
}

/// Calcolatore di metriche per layout diagrams
class QualityMetricsCalculator {
  /// Calcola tutte le metriche per un layout dato
  static QualityMetrics calculate({
    required Map<String, Offset> positions,
    required List<EdgeData> edges,
  }) {
    return QualityMetrics(
      crossingNumber: _calculateCrossingNumber(edges, positions),
      segmentUniformity: _calculateSegmentUniformity(edges, positions),
      spatialBalance: _calculateSpatialBalance(positions),
      edgeAngleVariance: _calculateEdgeAngleVariance(edges, positions),
      nodeSeparation: _calculateNodeSeparation(positions),
    );
  }

  /// METRICA 1: Crossing Number (normalizzato 0-1)
  static double _calculateCrossingNumber(
    List<EdgeData> edges,
    Map<String, Offset> positions,
  ) {
    if (edges.length < 2) return 0.0;

    int crossings = 0;
    final segments = edges.map((e) {
      return LineSegment(
        positions[e.from]!,
        positions[e.to]!,
      );
    }).toList();

    // Brute force O(n²) per tutti i segmenti
    for (int i = 0; i < segments.length; i++) {
      for (int j = i + 1; j < segments.length; j++) {
        if (_segmentsIntersect(segments[i], segments[j])) {
          crossings++;
        }
      }
    }

    // Normalizza: max possibile = n*(n-1)/2
    final maxCrossings = (edges.length * (edges.length - 1)) / 2;
    return (crossings / maxCrossings).clamp(0.0, 1.0);
  }

  /// METRICA 2: Segment Uniformity (variance-based)
  static double _calculateSegmentUniformity(
    List<EdgeData> edges,
    Map<String, Offset> positions,
  ) {
    if (edges.isEmpty) return 1.0;

    final lengths = edges.map((e) {
      final p1 = positions[e.from]!;
      final p2 = positions[e.to]!;
      return (p1 - p2).distance;
    }).toList();

    final mean = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance =
        lengths.map((l) => pow(l - mean, 2)).reduce((a, b) => a + b) /
            lengths.length;
    final stdDev = sqrt(variance);

    // Score alto = bassa deviazione (normalizzato)
    return (1.0 - (stdDev / mean)).clamp(0.0, 1.0);
  }

  /// METRICA 3: Spatial Balance (quanto è distribuito il layout)
  static double _calculateSpatialBalance(Map<String, Offset> positions) {
    if (positions.isEmpty) return 1.0;

    final coords = positions.values.toList();
    final xValues = coords.map((p) => p.dx);
    final yValues = coords.map((p) => p.dy);

    final xSpread = xValues.reduce(max) - xValues.reduce(min);
    final ySpread = yValues.reduce(max) - yValues.reduce(min);

    // Score alto = usa tutto lo spazio disponibile (0.4-0.8 range ideale)
    final avgSpread = (xSpread + ySpread) / 2;
    if (avgSpread < 0.4) return avgSpread / 0.4;
    if (avgSpread > 0.8) return 1.0 - (avgSpread - 0.8) / 0.2;
    return 1.0;
  }

  /// METRICA 4: Edge Angle Variance (variety direzionale)
  static double _calculateEdgeAngleVariance(
    List<EdgeData> edges,
    Map<String, Offset> positions,
  ) {
    if (edges.length < 2) return 1.0;

    final angles = edges.map((e) {
      final p1 = positions[e.from]!;
      final p2 = positions[e.to]!;
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      return atan2(dy, dx);
    }).toList();

    // Calcola distribuzione angolare (ideale: uniforme su 360°)
    final angleVariance = _calculateCircularVariance(angles);
    return angleVariance.clamp(0.0, 1.0);
  }

  /// METRICA 5: Node Separation (distanza minima tra nodi)
  static double _calculateNodeSeparation(Map<String, Offset> positions) {
    if (positions.length < 2) return 1.0;

    double minDistance = double.infinity;
    final nodes = positions.values.toList();

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < minDistance) minDistance = dist;
      }
    }

    // Ideale: minDistance >= 0.15
    return (minDistance / 0.15).clamp(0.0, 1.0);
  }

  // === HELPER METHODS ===

  /// Check intersezione tra due segmenti (no Bézier per semplicità)
  static bool _segmentsIntersect(LineSegment a, LineSegment b) {
    final dx1 = a.end.dx - a.start.dx;
    final dy1 = a.end.dy - a.start.dy;
    final dx2 = b.end.dx - b.start.dx;
    final dy2 = b.end.dy - b.start.dy;
    final dx3 = a.start.dx - b.start.dx;
    final dy3 = a.start.dy - b.start.dy;

    final denom = dx1 * dy2 - dy1 * dx2;
    if (denom.abs() < 1e-10) return false; // Paralleli

    final t = (dx3 * dy2 - dy3 * dx2) / denom;
    final u = (dx3 * dy1 - dy3 * dx1) / denom;

    return t >= 0 && t <= 1 && u >= 0 && u <= 1;
  }

  /// Varianza circolare per angoli
  static double _calculateCircularVariance(List<double> angles) {
    if (angles.isEmpty) return 0.0;

    final cosSum = angles.map((a) => cos(a)).reduce((a, b) => a + b);
    final sinSum = angles.map((a) => sin(a)).reduce((a, b) => a + b);

    final r = sqrt(cosSum * cosSum + sinSum * sinSum) / angles.length;
    return 1.0 - r; // High variance = good (variety)
  }
}

/// Dati edge per calcoli
class EdgeData {
  final String from;
  final String to;

  EdgeData(this.from, this.to);
}

/// Segmento lineare
class LineSegment {
  final Offset start;
  final Offset end;

  LineSegment(this.start, this.end);
}
