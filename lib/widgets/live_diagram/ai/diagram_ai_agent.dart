import 'dart:math';
import 'package:flutter/material.dart';
import '../schema/diagram_schema.dart';
import 'models/node_metadata.dart';
import 'scenario_request_v2.dart';
import 'semantic_engine.dart';
import 'quality_metrics.dart';
import 'viewport_layout_engine.dart';
import '../logic/geometry_engine.dart';
import '../logic/layout_engine.dart';

/// Agente AI Semantico per la gestione autonoma dei Live Flow Diagrams.
class DiagramAIAgent {
  final Random _random = Random();
  AdaptiveLayoutParams? _lastAdaptiveParams;

  static const Map<String, TopologyTemplate> _templates = {
    'diamond': TopologyTemplate(name: 'Diamond Layout', centerNode: true, satelliteRadius: 0.25, verticalSpread: 0.40),
    'tree': TopologyTemplate(name: 'Tree Layout', centerNode: false, satelliteRadius: 0.30, verticalSpread: 0.35),
    'circular': TopologyTemplate(name: 'Circular Layout', centerNode: true, satelliteRadius: 0.35, verticalSpread: 0.35),
    'layered': TopologyTemplate(name: 'Layered Layout', centerNode: false, satelliteRadius: 0.0, verticalSpread: 0.20),
    'force-directed': TopologyTemplate(name: 'Force-Directed Layout', centerNode: false, satelliteRadius: 0.0, verticalSpread: 0.0),
  };

  DiagramScene createScenarioFromDescription(ScenarioRequestV2 request) {
    print("LOG_IDENTIFICATIVO_UNICO_12345");
    if (request.viewportSize != null) {
      _lastAdaptiveParams = ViewportLayoutEngine.calculateAdaptiveLayout(
        viewportSize: request.viewportSize!,
        elementCount: request.elementCount,
        preferredSpacing: request.preferredSpacing ?? 0.0,
      );
    }

    ScenarioRequestV2 processedRequest = request;
    if (request.autoExpandContext && request.focusNode != null) {
      final expandedFlow = SemanticEngine.expandContextForNode(request.focusNode!, request.dataFlow);
      processedRequest = request.copyWith(dataFlow: expandedFlow);
    }

    final nodes = _analyzeNodesFromDescription(processedRequest);
    final template = SemanticEngine.inferTemplate(processedRequest);
    var positions = SemanticEngine.resolveImplicitNodes(nodes, processedRequest);

    if (positions.length < nodes.length) {
      positions = optimizeTopologyV2(
        nodes: nodes,
        template: template,
        focusNode: processedRequest.focusNode,
        existingPositions: positions,
        adaptiveParams: _lastAdaptiveParams,
      );
    }

    final Map<String, Offset> unifiedCPs = {};
    processedRequest.dataFlow.forEach((from, targets) {
      for (var to in targets) {
        unifiedCPs['$from-$to'] = GeometryEngine.calculateAdaptiveControlPoint(from, to, positions);
      }
    });

    final ghostPaths = _generateGhostPathsSynced(processedRequest.dataFlow, positions, unifiedCPs);
    final autoLabels = SemanticEngine.generateMissingLabels(processedRequest.dataFlow, processedRequest.phaseLabels);
    final enrichedRequest = processedRequest.copyWith(phaseLabels: autoLabels);
    final phases = _generateStoryPhasesSynced(enrichedRequest, unifiedCPs, positions);

    return DiagramScene(id: processedRequest.scenarioId, nodePositions: positions, ghostPaths: ghostPaths, phases: phases);
  }

  List<GhostPath> _generateGhostPathsSynced(Map<String, List<String>> flow, Map<String, Offset> positions, Map<String, Offset> cps) {
    final paths = <GhostPath>[];
    flow.forEach((from, targets) {
      for (final to in targets) {
        if (positions.containsKey(from) && positions.containsKey(to)) {
          paths.add(GhostPath(from, to, curved: true, cp: cps['$from-$to']));
        }
      }
    });
    return paths;
  }

  List<StoryPhase> _generateStoryPhasesSynced(ScenarioRequestV2 request, Map<String, Offset> cps, Map<String, Offset> positions) {
    final phases = <StoryPhase>[];
    final duration = 1.0 / (request.dataFlow.isEmpty ? 1 : request.dataFlow.length);
    int idx = 0;

    request.dataFlow.forEach((from, targets) {
      final elements = <VisualElement>[];
      for (final to in targets) {
        Offset labelOffset = Offset.zero;
        if (positions.containsKey(from) && positions.containsKey(to)) {
          final p1 = positions[from]!; final p2 = positions[to]!;
          double nx = -(p2.dy - p1.dy); double ny = (p2.dx - p1.dx);
          final len = sqrt(nx * nx + ny * ny);
          if (len > 0) { nx /= len; ny /= len; }
          final midX = (p1.dx + p2.dx) / 2; final midY = (p1.dy + p2.dy) / 2;
          if (nx * (0.5 - midX) + ny * (0.5 - midY) > 0) { nx = -nx; ny = -ny; }
          labelOffset = Offset(nx * 40, ny * 40);
          final estPos = Offset(midX + (nx * 0.1), midY + (ny * 0.1));
          for (final nodePos in positions.values) {
            if ((estPos - nodePos).distance < 0.15) { labelOffset = -labelOffset; break; }
          }
        }
        elements.add(NeonFlow(fromNode: from, toNode: to, color: _getColorForPhase(idx), isCurved: true, controlPointOffset: cps['$from-$to']));
        elements.add(FloatingLabel(text: request.phaseLabels?[idx] ?? 'DATA FLOW', anchorNodeA: from, anchorNodeB: to, color: _getColorForPhase(idx), offset: labelOffset));
      }
      phases.add(StoryPhase(id: 'phase_$idx', startT: idx * duration, endT: (idx + 1) * duration, elements: elements));
      idx++;
    });
    return phases;
  }

  Map<String, Offset> optimizeTopologyV2({required List<String> nodes, required String template, String? focusNode, QualityPreset qualityPreset = QualityPreset.balanced, Map<String, Offset>? existingPositions, AdaptiveLayoutParams? adaptiveParams}) {
    var tpl = _templates[template] ?? _templates['diamond']!;
    if (adaptiveParams != null) tpl = tpl.copyWithAdaptive(adaptiveParams);
    final margin = adaptiveParams?.dynamicMargin ?? 0.12;
    Map<String, Offset> positions = existingPositions != null ? Map<String, Offset>.from(existingPositions) : {};

    if (positions.isEmpty || adaptiveParams != null) {
      if (adaptiveParams != null) {
        positions = _distributeNodesViewportAware(nodes, adaptiveParams, focusNode: focusNode, tpl: tpl);
      } else if (template == 'layered') {
        positions = _layeredLayout(nodes, focusNode);
      } else if (template == 'force-directed') {
        positions = _forceDirectedLayout(nodes, qualityPreset.maxIterations);
      } else if (focusNode != null && tpl.centerNode) {
        positions[focusNode] = const Offset(0.50, 0.40);
        positions.addAll(GeometryEngine.arrangeSatellites(nodes.where((n) => n != focusNode).toList(), center: positions[focusNode]!, radius: tpl.satelliteRadius, verticalOffset: tpl.verticalSpread));
      } else {
        positions = _distributeNodes(nodes, tpl);
      }
    }

    positions = LayoutEngine.applyForceDirected(positions, qualityPreset.maxIterations, margin: margin, useAdaptiveGravity: adaptiveParams != null);

    if (qualityPreset == QualityPreset.balanced || qualityPreset == QualityPreset.premium) {
      positions = LayoutEngine.repelFromPaths(positions, 3);
    }

    if (qualityPreset.enableFullGeometry) positions = _optimizeForPerception(positions, nodes);
    return positions;
  }

  Map<String, Offset> _optimizeForPerception(Map<String, Offset> positions, List<String> nodes) {
    var best = Map<String, Offset>.from(positions);
    var bestScore = double.negativeInfinity;
    for (int iter = 0; iter < 20; iter++) {
      final candidate = _perturbPositions(best, 0.03);
      final score = QualityMetricsCalculator.calculate(positions: candidate, edges: []).compositeScore;
      if (score > bestScore) { best = candidate; bestScore = score; }
    }
    return best;
  }

  Map<String, Offset> _perturbPositions(Map<String, Offset> positions, double magnitude) {
    final perturbed = <String, Offset>{};
    positions.forEach((node, pos) {
      perturbed[node] = Offset((pos.dx + (_random.nextDouble() - 0.5) * magnitude).clamp(0.05, 0.95), (pos.dy + (_random.nextDouble() - 0.5) * magnitude).clamp(0.05, 0.95));
    });
    return perturbed;
  }

  List<String> _analyzeNodesFromDescription(ScenarioRequestV2 request) {
    final nodes = <String>{};
    nodes.addAll(request.dataFlow.keys);
    for (final targets in request.dataFlow.values) { nodes.addAll(targets); }
    return nodes.toList();
  }

  Map<String, Offset> _layeredLayout(List<String> nodes, String? focusNode) {
    final positions = <String, Offset>{};
    final yStep = 0.8 / (nodes.length > 1 ? nodes.length : 1);
    for (int i = 0; i < nodes.length; i++) { positions[nodes[i]] = Offset(0.5, 0.1 + i * yStep); }
    return positions;
  }

  Map<String, Offset> _forceDirectedLayout(List<String> nodes, int iterations) {
    final positions = <String, Offset>{};
    for (final node in nodes) { positions[node] = Offset(0.2 + _random.nextDouble() * 0.6, 0.2 + _random.nextDouble() * 0.6); }
    return LayoutEngine.applyForceDirected(positions, iterations, useAdaptiveGravity: false);
  }

  Map<String, Offset> _distributeNodes(List<String> nodes, TopologyTemplate tpl) {
    final positions = <String, Offset>{};
    final cols = sqrt(nodes.length).ceil();
    for (int i = 0; i < nodes.length; i++) { positions[nodes[i]] = Offset(0.2 + (i % cols) * 0.3, 0.2 + (i ~/ cols) * 0.3); }
    return positions;
  }

  Color _getColorForPhase(int index) {
    const colors = [Colors.cyanAccent, Colors.purpleAccent, Colors.orangeAccent, Colors.greenAccent];
    return colors[index % colors.length];
  }

  Map<String, Offset> _distributeNodesViewportAware(List<String> nodes, AdaptiveLayoutParams params, {String? focusNode, required TopologyTemplate tpl}) {
    final positions = <String, Offset>{};
    if (nodes.isEmpty) return positions;
    final margin = params.dynamicMargin;
    final usableW = 1.0 - (2 * margin); final usableH = 1.0 - (2 * margin);
    int cols = sqrt(nodes.length).ceil();
    if (params.elementCount > 12) cols = min(5, max(2, (usableW / 0.2).toInt()));
    int rows = (nodes.length / cols).ceil();
    final cellW = usableW / cols; final cellH = usableH / rows;

    if (focusNode != null && tpl.centerNode && nodes.contains(focusNode)) {
      positions[focusNode] = const Offset(0.5, 0.5);
      final remaining = nodes.where((n) => n != focusNode).toList();
      int idx = 0;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (idx >= remaining.length) break;
          final cellCX = margin + (c * cellW) + (cellW / 2); final cellCY = margin + (r * cellH) + (cellH / 2);
          double x = (idx % 2 == 0) ? cellCX - cellW * 0.35 : cellCX + cellW * 0.35;
          double y = (idx % 2 == 0) ? cellCY - cellH * 0.35 : cellCY + cellH * 0.35;
          if ((x - 0.5).abs() > 0.05 || (y - 0.5).abs() > 0.05) {
            positions[remaining[idx]] = Offset(x.clamp(margin, 1.0 - margin), y.clamp(margin, 1.0 - margin));
            idx++;
          }
        }
      }
    } else {
      int idx = 0;
      for (int r = 0; r < rows && idx < nodes.length; r++) {
        for (int c = 0; c < cols && idx < nodes.length; c++) {
          final cellCX = margin + (c * cellW) + (cellW / 2); final cellCY = margin + (r * cellH) + (cellH / 2);
          double x = ((r + c) % 2 == 0) ? cellCX - cellW * 0.35 : cellCX + cellW * 0.35;
          double y = ((r + c) % 2 == 0) ? cellCY - cellH * 0.35 : cellCY + cellH * 0.35;
          positions[nodes[idx]] = Offset(x.clamp(margin, 1.0 - margin), y.clamp(margin, 1.0 - margin));
          idx++;
        }
      }
    }
    return positions;
  }

  DiagramScene optimizeExistingScenario(DiagramScene original, {bool optimizeLayout = true, bool simplifyPaths = true, bool balanceTiming = true, Size? viewportSize, int elementCount = 4, Map<String, List<String>>? dataFlow}) {
    AdaptiveLayoutParams? adaptiveParams;
    if (viewportSize != null) {
      adaptiveParams = ViewportLayoutEngine.calculateAdaptiveLayout(viewportSize: viewportSize, elementCount: original.nodePositions.length + original.ghostPaths.length, preferredSpacing: 0.0);
    }
    if (optimizeLayout) {
      final newPos = optimizeTopologyV2(nodes: original.nodePositions.keys.toList(), template: 'force-directed', existingPositions: original.nodePositions, qualityPreset: QualityPreset.balanced, adaptiveParams: adaptiveParams);
      List<StoryPhase> newPhases = original.phases;
      if (dataFlow != null && newPos.isNotEmpty && original.id != "ML_EXPANSION") {
        final Map<String, Offset> cps = {};
        for (final gp in original.ghostPaths) { if (gp.cp != null) cps['${gp.from}-${gp.to}'] = gp.cp!; }
        for (final from in dataFlow.keys) {
          for (final to in dataFlow[from]!) {
            if (!cps.containsKey('$from-$to')) cps['$from-$to'] = GeometryEngine.calculateAdaptiveControlPoint(from, to, newPos);
          }
        }
        newPhases = _generateStoryPhasesSynced(ScenarioRequestV2(scenarioId: original.id, dataFlow: dataFlow), cps, newPos);
      }
      return DiagramScene(id: original.id, nodePositions: newPos, ghostPaths: original.ghostPaths, phases: newPhases);
    }
    return original;
  }

  ValidationResult validateScenario(DiagramScene scene) => ValidationResult(isValid: scene.nodePositions.isNotEmpty, errors: scene.nodePositions.isEmpty ? ["Nessun nodo"] : [], warnings: []);
  String exportScenarioAsCode(DiagramScene scene) => "// Export feature disabilitata";
}
