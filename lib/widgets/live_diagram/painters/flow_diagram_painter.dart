// /lib/widgets/live_diagram/painters/flow_diagram_painter.dart

import 'package:flutter/material.dart';
import 'package:pesca_app/screens/mission_control/models.dart';
import '../logic/diagram_topology.dart';
import '../schema/diagram_schema.dart';
import 'ml_story_renderer.dart';

class FlowDiagramPainter extends CustomPainter {
  final double flowAnimation;
  final double pulseAnimation;
  final double mlStoryAnimation;
  final bool isMlStoryActive;
  final Map<String, WorkerStatus> workers;
  final String? selectedNode;
  final Map<String, List<String>> connectionsMap;
  final DiagramTopology topo;
  final DiagramScene? activeScene;

  // Helper interno
  Offset? _getStdPosFromTopo(String id) {
    switch (id) {
      case "ML_MODEL":
        return topo.stdMlPos;
      case "SUPER_AGENT":
        return topo.stdSuperPos;
      case "SQLITE":
        return topo.stdSqlitePos;
      case "LLM":
        return topo.stdLlmPos;
      case "API":
        return topo.stdApiPos;
      case "CHROMA":
        return topo.stdChromaPos;
      case "WEATHER":
        return topo.stdWeatherPos;
      case "MARINE":
        return topo.stdMarinePos;
      case "SPECIES":
        return topo.stdSpeciesPos;
      case "MEMORY":
        return topo.stdMemoryPos;
      default:
        return null;
    }
  }

  FlowDiagramPainter({
    required this.flowAnimation,
    required this.pulseAnimation,
    required this.mlStoryAnimation,
    required this.isMlStoryActive,
    required this.workers,
    required this.connectionsMap,
    required this.topo,
    this.selectedNode,
    this.activeScene,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double t = mlStoryAnimation;
    final double moveCurve =
        Curves.easeInOutCubic.transform((t < 0.1) ? t * 10 : 1.0);

    // HELPER: Coordinate assolute per posizioni 0.0-1.0
    Offset toAbs(Offset rel) {
      const double padding = 45.0;
      final double safeW = size.width - (padding * 2);
      final double safeH = size.height - (padding * 2);
      return Offset(
        padding + (rel.dx * safeW),
        padding + (rel.dy * safeH),
      );
    }

    bool isInScene(String id) =>
        activeScene?.nodePositions.containsKey(id) ?? false;

    // 2. CALCOLO POSIZIONI CENTRALI (Nessun offset manuale aggiunto)
    Map<String, Offset> currentPositions = {};

    // A. SCENE NODES (Richiede conversione toAbs per posizioni relative)
    if (activeScene != null) {
      activeScene!.nodePositions.forEach((nodeId, relPos) {
        final targetAbs = toAbs(relPos);
        final stdPosAbs = _getStdPosFromTopo(nodeId);

        if (stdPosAbs != null) {
          // Topo Abs -> Target Abs (Transizione diretta centro-centro)
          currentPositions[nodeId] =
              Offset.lerp(stdPosAbs, targetAbs, moveCurve)!;
        } else {
          // Spawn da API
          currentPositions[nodeId] =
              Offset.lerp(topo.stdApiPos, targetAbs, moveCurve)!;
        }
      });
    }

    // B. STANDARD NODES
    final standardNodes = [
      'SUPER_AGENT',
      'ML_MODEL',
      'SQLITE',
      'API',
      'MARINE',
      'WEATHER',
      'SPECIES',
      'MEMORY'
    ];

    for (var nodeId in standardNodes) {
      if (!currentPositions.containsKey(nodeId)) {
        final stdPosAbs = _getStdPosFromTopo(nodeId);
        if (stdPosAbs != null) {
          // Usiamo direttamente il centro geometrico definito in Topology
          currentPositions[nodeId] = stdPosAbs;
        }
      }
    }

    // C. EXITING NODES LOGIC
    void applyExitLogic(String id, Offset stdAbs, Offset exitAbs) {
      if (!isInScene(id)) {
        currentPositions[id] = Offset.lerp(stdAbs, exitAbs, moveCurve)!;
      }
    }

    applyExitLogic("API", topo.stdApiPos, topo.exitTop);
    applyExitLogic("LLM", topo.stdLlmPos, topo.exitTop);
    applyExitLogic("CHROMA", topo.stdChromaPos, topo.exitBottom);
    applyExitLogic("WEATHER", topo.stdWeatherPos, topo.exitBottom);
    applyExitLogic("MARINE", topo.stdMarinePos, topo.exitBottom);
    applyExitLogic("SPECIES", topo.stdSpeciesPos, topo.exitBottom);
    applyExitLogic("MEMORY", topo.stdMemoryPos, topo.exitBottom);

    // 3. RENDER LAYERS
    if (mlStoryAnimation > 0.0 && activeScene != null) {
      // Gli orbitali saranno ora centrati perché currentPositions punta al centro esatto
      final renderer =
          MlStoryRenderer(canvas, mlStoryAnimation, currentPositions);
      renderer.render(activeScene!);
    }

    if (mlStoryAnimation < 1.0) {
      double op = (1.0 - mlStoryAnimation * 15.0).clamp(0.0, 1.0);
      if (op > 0) {
        _drawStandardLines(canvas, op, currentPositions);
      }
    }
  }

  void _drawStandardLines(
      Canvas canvas, double opacity, Map<String, Offset> positions) {
    void draw(String id1, String id2, Color c, String workerKey, {Color? pc}) {
      // Sicurezza: Disegna solo se entrambe le posizioni sono calcolate
      if (!positions.containsKey(id1) || !positions.containsKey(id2)) return;

      final p1 = positions[id1]!;
      final p2 = positions[id2]!;

      double workerLoad = workers[workerKey]?.load ?? 0.0;
      double flowRate = flowAnimation * (0.1 + (workerLoad * 0.4));

      bool isActive = selectedNode == null ||
          (selectedNode == id1 || selectedNode == id2) ||
          ((connectionsMap[selectedNode] ?? []).contains(id1) &&
              (connectionsMap[selectedNode] ?? []).contains(id2));

      double finalAlpha = (isActive ? 1.0 : 0.05) * opacity;
      if (finalAlpha <= 0.001) return;

      _drawNeonLine(
          canvas, p1, p2, c.withOpacity(finalAlpha), isActive ? flowRate : 0,
          particleColor: pc);
    }

    // Disegna usando i riferimenti centralizzati
    draw("ML_MODEL", "SUPER_AGENT", Colors.cyanAccent, 'SUPER_AGENT_CORE');
    draw("SUPER_AGENT", "LLM", Colors.purpleAccent, 'SUPER_AGENT_CORE');

    draw("SUPER_AGENT", "WEATHER", Colors.white24, 'WEATHER_ANALYST');
    draw("SUPER_AGENT", "MARINE", Colors.white24, 'MARINE_SPECIALIST');
    draw("SUPER_AGENT", "SPECIES", Colors.white24, 'SPECIES_ADVISOR');
    draw("SUPER_AGENT", "MEMORY", Colors.white24, 'MEMORY_RETRIEVER');

    draw("WEATHER", "API", Colors.blue, 'WEATHER_ANALYST',
        pc: Colors.blueAccent);
    draw("MARINE", "API", Colors.cyan, 'MARINE_SPECIALIST',
        pc: Colors.cyanAccent);
    draw("SPECIES", "CHROMA", Colors.teal, 'SPECIES_ADVISOR',
        pc: Colors.tealAccent);
    draw("MEMORY", "SQLITE", Colors.orange, 'MEMORY_RETRIEVER',
        pc: Colors.orangeAccent);
  }

  void _drawNeonLine(
      Canvas canvas, Offset start, Offset end, Color color, double flowRate,
      {Color? particleColor}) {
    if (color.opacity <= 0.001) return;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.cubicTo(start.dx, (start.dy + end.dy) / 2, end.dx,
        (start.dy + end.dy) / 2, end.dx, end.dy);

    final lineThickness = 1.0 + (flowRate * 4.0);

    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(color.opacity * 0.2)
          ..strokeWidth = lineThickness * 3
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = lineThickness
          ..style = PaintingStyle.stroke);

    if (flowRate > 0.001) {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final pos = ((flowRate * 5) * metric.length) % metric.length;
        final tangent = metric.getTangentForOffset(pos);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 2.5,
              Paint()..color = Colors.white.withOpacity(color.opacity));
          canvas.drawCircle(
              tangent.position,
              5.0,
              Paint()
                ..color =
                    (particleColor ?? color).withOpacity(0.6 * color.opacity)
                ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlowDiagramPainter oldDelegate) => true;
}
