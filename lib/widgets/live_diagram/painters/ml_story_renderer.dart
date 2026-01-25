// /lib/widgets/live_diagram/painters/ml_story_renderer.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../schema/diagram_schema.dart';

/// Engine Generico: Prende una scena (Data) e la disegna sul Canvas.
class MlStoryRenderer {
  final Canvas canvas;
  final double t; // Tempo globale 0.0 -> 1.0
  final Map<String, Offset>
      nodeLocations; // Mappa ID -> Coordinate Pixel attuali

  MlStoryRenderer(this.canvas, this.t, this.nodeLocations);

  void render(DiagramScene scene) {
    // 1. Disegna Blueprint (Ghost Lines)
    _renderGhosts(scene.ghostPaths);

    // 2. Disegna Fasi Attive
    for (final phase in scene.phases) {
      if (t >= phase.startT && t <= phase.endT) {
        // Calcolo progresso locale (0.0 -> 1.0) dentro la fase
        double duration = phase.endT - phase.startT;
        double localT = (duration > 0)
            ? ((t - phase.startT) / duration).clamp(0.0, 1.0)
            : 0.0;

        // Renderizza elementi
        for (final element in phase.elements) {
          if (element is NeonFlow) _drawNeonFlow(element, localT);
          if (element is FloatingLabel) _drawLabel(element, localT);
          if (element is OrbitalEffect) _drawOrbitals(element, localT);
        }
      }
    }
  }

  void _renderGhosts(List<GhostPath> paths) {
    // Fade in iniziale generico per la struttura (Moving Blueprint)
    // Appaiono subito (0.0) e seguono i nodi
    double setupProgress = t.clamp(0.0, 0.15) / 0.15;
    double op = setupProgress * 0.35; // Max 35% opacità

    if (op <= 0.01) return;

    final paint = Paint()
      ..color = Colors.grey.withOpacity(op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final path in paths) {
      if (nodeLocations.containsKey(path.from) &&
          nodeLocations.containsKey(path.to)) {
        Offset p1 = nodeLocations[path.from]!;
        Offset p2 = nodeLocations[path.to]!;

        if (path.curved) {
          // Calcolo Control Point relativo
          Offset cpOffset = path.cp ?? Offset.zero;
          // CP è relativo al punto medio per semplicità geometrica
          Offset mid = (p1 + p2) / 2;
          Offset cp1 = mid + cpOffset;

          Path p = Path();
          p.moveTo(p1.dx, p1.dy);

          if (path.cp2 != null) {
            Offset cp2 = mid + path.cp2!;
            p.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
          } else {
            p.quadraticBezierTo(cp1.dx, cp1.dy, p2.dx, p2.dy);
          }
          canvas.drawPath(p, paint);
        } else {
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  void _drawNeonFlow(NeonFlow flow, double progress) {
    if (!nodeLocations.containsKey(flow.fromNode) ||
        !nodeLocations.containsKey(flow.toNode)) return;

    Offset p1 = nodeLocations[flow.fromNode]!;
    Offset p2 = nodeLocations[flow.toNode]!;

    // Logica Opacità Ciclica (Trapezoidale Standard)
    // In 15%, Hold, Out 15%
    double op = (progress < 0.15)
        ? (progress / 0.15)
        : ((progress > 0.85) ? (1.0 - progress) / 0.15 : 1.0);

    _drawPrimitiveLine(
      p1,
      p2,
      flow.color.withOpacity(op),
      progress,
      flow.isCurved,
      flow.controlPointOffset,
      flow.controlPoint2Offset, // Nuovo parametro
    );
  }

  void _drawLabel(FloatingLabel label, double progress) {
    if (!nodeLocations.containsKey(label.anchorNodeA) ||
        !nodeLocations.containsKey(label.anchorNodeB)) return;

    // Opacità sincronizzata Trapezoidale
    double op = (progress < 0.15)
        ? (progress / 0.15)
        : ((progress > 0.85) ? (1.0 - progress) / 0.15 : 1.0);
    if (op <= 0.05) return;

    Offset p1 = nodeLocations[label.anchorNodeA]!;
    Offset p2 = nodeLocations[label.anchorNodeB]!;

    // Calcolo posizione
    Offset basePos = Offset.lerp(p1, p2, label.lerp)!;
    Offset finalPos = basePos + label.offset;

    _drawPrimitiveLabel(label.text, finalPos, label.color, op);
  }

  void _drawOrbitals(OrbitalEffect effect, double progress) {
    if (!nodeLocations.containsKey(effect.targetNode)) return;

    // Finestra opacità custom per orbitali
    double op = (progress < 0.2)
        ? (progress / 0.2)
        : ((progress > 0.8) ? (1.0 - progress) / 0.2 : 1.0);
    if (op <= 0.05) return;

    Offset center = nodeLocations[effect.targetNode]!;
    // Rotazione basata sul tempo globale (t) per continuità, moltiplicata per speed
    double spin = t * effect.speed;

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Disegno 3 anelli standard (Outer, Mid, Inner)
    // 1. Outer Ring (Segmentato 4)
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: 40),
          spin + (i * 1.57),
          0.8,
          false,
          paint..color = effect.color.withOpacity(op));
    }
    // 2. Mid Ring (Continuo)
    canvas.drawCircle(
        center,
        36,
        paint
          ..strokeWidth = 1.0
          ..color = effect.color.withOpacity(op * 0.5));
    // 3. Inner Ring (Reverse, Bianco, Segmentato 3)
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: 32),
          (-spin * 1.5) + (i * 2.09),
          1.2,
          false,
          paint
            ..strokeWidth = 2.5
            ..color = Colors.white.withOpacity(op));
    }
  }

  // --- PRIMITIVE GRAFICHE DI BASSO LIVELLO ---

  void _drawPrimitiveLine(Offset start, Offset end, Color color, double flowT,
      bool curved, Offset? cpOffset,
      [Offset? cp2Offset]) {
    if (color.opacity <= 0.01) return;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    if (curved) {
      Offset mid = (start + end) / 2;
      Offset cp1 = mid + (cpOffset ?? Offset.zero);

      if (cp2Offset != null) {
        Offset cp2 = mid + cp2Offset;
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
      } else {
        path.quadraticBezierTo(cp1.dx, cp1.dy, end.dx, end.dy);
      }
    } else {
      // Cubic di default per linee "dritte" morbide (S-shape automatica)
      path.cubicTo(start.dx, (start.dy + end.dy) / 2, end.dx,
          (start.dy + end.dy) / 2, end.dx, end.dy);
    }

    // Glow e Core
    final strokeW = 1.0 + (flowT * 2.0); // Leggera pulsazione spessore
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(color.opacity * 0.5)
          ..strokeWidth = strokeW * 3
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke);

    // Particella
    if (flowT > 0.0) {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final pos = flowT * metric.length;
        final tangent = metric.getTangentForOffset(pos);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 3.0,
              Paint()..color = Colors.white.withOpacity(color.opacity));
          // Scia
          canvas.drawPath(
              metric.extractPath(max(0, pos - 40), pos),
              Paint()
                ..color = color.withOpacity(0.5 * color.opacity)
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke);
        }
      }
    }
  }

  void _drawPrimitiveLabel(
      String text, Offset pos, Color color, double opacity) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: 10,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold),
    );
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    final width = textPainter.width + 12;
    final height = textPainter.height + 6;
    final rect = Rect.fromCenter(center: pos, width: width, height: height);

    // Background HUD
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = Colors.black.withOpacity(0.8 * opacity)
          ..style = PaintingStyle.fill);
    // Border
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = color.withOpacity(0.5 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    textPainter.paint(
        canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }
}
