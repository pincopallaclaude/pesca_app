// /lib/widgets/live_diagram/ai/viewport_layout_engine.dart

import 'package:flutter/material.dart';
import 'dart:math';

/// Engine per il calcolo adattivo di layout basato su dimensioni viewport e numero elementi.
class ViewportLayoutEngine {
  /// Calcola parametri di layout adattivi
  static AdaptiveLayoutParams calculateAdaptiveLayout({
    required Size viewportSize,
    required int elementCount,
    required double preferredSpacing,
  }) {
    final width = viewportSize.width;
    final height = viewportSize.height;

    final dynamicMargin = _calculateDynamicMargin(elementCount);
    final baseCollisionRadius = _calculateCollisionRadius(elementCount);
    final satelliteRadius = _calculateSatelliteRadius(elementCount);
    final verticalSpread = _calculateVerticalSpread(elementCount);

    final minSpacing = preferredSpacing > 0
        ? preferredSpacing
        : _calculateMinimumSpacing(elementCount);

    return AdaptiveLayoutParams(
      dynamicMargin: dynamicMargin,
      baseCollisionRadius: baseCollisionRadius,
      satelliteRadius: satelliteRadius,
      verticalSpread: verticalSpread,
      minSpacing: minSpacing,
      viewportWidth: width,
      viewportHeight: height,
      elementCount: elementCount,
    );
  }

  static double _calculateDynamicMargin(int elementCount) {
    double baseMargin = 0.10;
    if (elementCount <= 4) {
      baseMargin = 0.05; // Per 4 elementi: spingere ai 4 angoli
    } else if (elementCount == 5) {
      baseMargin = 0.05; // Per 5 elementi: stesso margine aggressivo
    } else if (elementCount <= 7) {
      baseMargin = 0.06; // Per 5-7 elementi
    } else if (elementCount >= 10) {
      baseMargin = max(0.05, 0.08 - (elementCount - 10) * 0.01);
    }
    return baseMargin.clamp(0.05, 0.20);
  }

  static double _calculateCollisionRadius(int elementCount) {
    double baseRadius = 0.12;
    if (elementCount <= 4) {
      baseRadius = 0.15;
    } else if (elementCount > 10) {
      baseRadius = max(0.08, 0.12 - (elementCount - 10) * 0.01);
    }
    return baseRadius.clamp(0.08, 0.18);
  }

  static double _calculateSatelliteRadius(int elementCount) {
    double baseRadius = 0.25;
    if (elementCount > 8) {
      baseRadius = max(0.15, 0.25 - (elementCount - 8) * 0.02);
    }
    return baseRadius.clamp(0.10, 0.35);
  }

  static double _calculateVerticalSpread(int elementCount) {
    double spread = 0.35;
    if (elementCount <= 4) {
      spread = 0.25;
    } else if (elementCount > 8) {
      spread = min(0.50, 0.35 + (elementCount - 8) * 0.03);
    }
    return spread.clamp(0.20, 0.60);
  }

  static double _calculateMinimumSpacing(int elementCount) {
    double baseSpacing = 0.05;
    if (elementCount > 10) {
      baseSpacing = max(0.03, 0.05 - (elementCount - 10) * 0.005);
    }
    return baseSpacing.clamp(0.02, 0.08);
  }
}

/// Parametri di layout calcolati adattivamente
class AdaptiveLayoutParams {
  final double dynamicMargin;
  final double baseCollisionRadius;
  final double satelliteRadius;
  final double verticalSpread;
  final double minSpacing;
  final double viewportWidth;
  final double viewportHeight;
  final int elementCount;

  AdaptiveLayoutParams({
    required this.dynamicMargin,
    required this.baseCollisionRadius,
    required this.satelliteRadius,
    required this.verticalSpread,
    required this.minSpacing,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.elementCount,
  });

  @override
  String toString() {
    return '''=== ADAPTIVE LAYOUT PARAMS ===
Viewport: ${viewportWidth.toStringAsFixed(0)}x${viewportHeight.toStringAsFixed(0)}
Elements: $elementCount
Margin: ${(dynamicMargin * 100).toStringAsFixed(1)}%
CollisionRadius: ${baseCollisionRadius.toStringAsFixed(3)}
SatelliteRadius: ${satelliteRadius.toStringAsFixed(3)}
VerticalSpread: ${(verticalSpread * 100).toStringAsFixed(1)}%
MinSpacing: ${minSpacing.toStringAsFixed(3)}''';
  }
}
