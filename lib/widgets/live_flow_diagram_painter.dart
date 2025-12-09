// /lib/widgets/live_flow_diagram_painter.dart

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../screens/mission_control/models.dart';

class FlowDiagramPainter extends CustomPainter {
  final double flowAnimation;
  final double pulseAnimation;
  final Map<String, WorkerStatus> workers;
  final Size containerSize;
  final String? selectedNode;
  final Map<String, List<String>> connectionsMap;

  FlowDiagramPainter({
    required this.flowAnimation,
    required this.pulseAnimation,
    required this.workers,
    required this.containerSize,
    required this.connectionsMap,
    this.selectedNode,
  });

  bool _shouldDrawLine(String from, String to) {
    if (selectedNode == null) return true;
    if (selectedNode == from || selectedNode == to) return true;
    final isFromSelectedPath =
        connectionsMap[selectedNode]?.contains(to) ?? false;
    final isToSelectedPath =
        connectionsMap[selectedNode]?.contains(from) ?? false;
    return isFromSelectedPath || isToSelectedPath;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = containerSize.width;
    final h = containerSize.height;
    final centerX = w / 2;

    // Coordinate (Devono coincidere con il layout del Widget)
    final mlPos = Offset(w * 0.15, h * 0.15);
    final llmPos = Offset(w * 0.85, h * 0.15);
    final superAgentPos = Offset(centerX, h * 0.15);
    final apiPos = Offset(centerX, h * 0.35);
    final sqlitePos = Offset(w * 0.2, h * 0.5);
    final chromaPos = Offset(w * 0.8, h * 0.5);

    final workerY = h * 0.82;
    final step = (w - 20) / 8; // Calcolo dinamico dello step
    final meteoPos = Offset(10 + step * 1, workerY);
    final marinePos = Offset(10 + step * 3, workerY);
    final speciesPos = Offset(10 + step * 5, workerY);
    final memoryPos = Offset(10 + step * 7, workerY);

    void draw(
        String id1, Offset p1, String id2, Offset p2, Color c, String workerKey,
        {Color? pc}) {
      double workerLoad = workers[workerKey]?.load ?? 0.0;
      // Velocità flusso basata sul carico
      double flowRate = flowAnimation * (0.1 + (workerLoad * 0.4));
      bool active = _shouldDrawLine(id1, id2);
      _drawNeonLine(canvas, p1, p2, active ? c : c.withOpacity(0.01),
          active ? flowRate : 0,
          particleColor: active ? pc : Colors.transparent);
    }

    // Disegno Connessioni
    draw("ML_MODEL", mlPos, "SUPER_AGENT", superAgentPos, Colors.cyanAccent,
        'SUPER_AGENT_CORE');
    draw("SUPER_AGENT", superAgentPos, "LLM", llmPos, Colors.purpleAccent,
        'SUPER_AGENT_CORE');

    draw("SUPER_AGENT", superAgentPos, "METEO", meteoPos, Colors.white24,
        'METEO_ANALYST');
    draw("SUPER_AGENT", superAgentPos, "MARINE", marinePos, Colors.white24,
        'MARINE_SPECIALIST');
    draw("SUPER_AGENT", superAgentPos, "SPECIES", speciesPos, Colors.white24,
        'SPECIES_ADVISOR');
    draw("SUPER_AGENT", superAgentPos, "MEMORY", memoryPos, Colors.white24,
        'MEMORY_RETRIEVER');

    draw("METEO", meteoPos, "API", apiPos, Colors.blue, 'METEO_ANALYST',
        pc: Colors.blueAccent);
    draw("MARINE", marinePos, "API", apiPos, Colors.cyan, 'MARINE_SPECIALIST',
        pc: Colors.cyanAccent);
    draw("SPECIES", speciesPos, "CHROMA", chromaPos, Colors.teal,
        'SPECIES_ADVISOR',
        pc: Colors.tealAccent);
    draw("MEMORY", memoryPos, "SQLITE", sqlitePos, Colors.orange,
        'MEMORY_RETRIEVER',
        pc: Colors.orangeAccent);
  }

  void _drawNeonLine(
      Canvas canvas, Offset start, Offset end, Color color, double flowRate,
      {Color? particleColor}) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    final cp1 = Offset(start.dx, (start.dy + end.dy) / 2);
    final cp2 = Offset(end.dx, (start.dy + end.dy) / 2);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    final lineThickness = 1.0 + (flowRate * 6.0);

    // Glow esterno
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.15)
          ..strokeWidth = lineThickness * 3
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    // Linea centrale
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.5)
          ..strokeWidth = lineThickness * 1.2
          ..style = PaintingStyle.stroke);

    // Particelle
    if (flowRate > 0.001) {
      final pColor = particleColor ?? color;
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final pos = ((flowRate * 5) * metric.length) % metric.length;
        final tangent = metric.getTangentForOffset(pos);
        if (tangent != null) {
          canvas.drawCircle(
              tangent.position, 2.0, Paint()..color = Colors.white);
          canvas.drawCircle(
              tangent.position,
              4.0,
              Paint()
                ..color = pColor.withOpacity(0.8)
                ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlowDiagramPainter oldDelegate) =>
      oldDelegate.flowAnimation != flowAnimation ||
      oldDelegate.selectedNode != selectedNode;
}
