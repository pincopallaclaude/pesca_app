// /lib/widgets/live_diagram/ai/semantic_engine.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'scenario_request_v2.dart';
import 'models/node_metadata.dart';

/// Motore di inferenza semantica per layout intelligente.
/// Gestisce l'espansione del contesto, l'inferenza del template e il posizionamento geometrico.
class SemanticEngine {
  /// Espande il grafo partendo dal Focus Node per includere dipendenze critiche
  static Map<String, List<String>> expandContextForNode(
    String focusNode,
    Map<String, List<String>> existingFlow,
  ) {
    final newFlow = Map<String, List<String>>.from(existingFlow);
    final visited = <String>{focusNode};
    final queue = <String>[focusNode];

    if (!newFlow.containsKey(focusNode)) newFlow[focusNode] = [];

    while (queue.isNotEmpty) {
      final currentNodeId = queue.removeAt(0);
      final metadata = GlobalNodeRegistry.get(currentNodeId);

      if (metadata != null) {
        // Analisi Output: Connessioni tipiche registrate nel metadata
        for (final connection in metadata.typicalConnections) {
          newFlow.putIfAbsent(currentNodeId, () => []);
          if (!newFlow[currentNodeId]!.contains(connection)) {
            newFlow[currentNodeId]!.add(connection);
          }
          if (!visited.contains(connection)) {
            visited.add(connection);
            // queue.add(connection); // FIX: Stop BFS recursion
          }
        }

        // Input Euristici: Integrazione semantica inversa (es. Sensori verso API)
        if (metadata.category == 'sensor') {
          newFlow.putIfAbsent('API', () => []);
          if (!newFlow['API']!.contains(currentNodeId)) {
            newFlow['API']!.add(currentNodeId);
          }
        }
      }
    }
    return newFlow;
  }

  /// Inferisce il template di layout ottimale basandosi sulla richiesta o sulla topologia del grafo
  static String inferTemplate(ScenarioRequestV2 request) {
    if (request.layoutTemplate != null) return request.layoutTemplate!;
    if (request.semanticType != null) {
      return _inferFromSemanticType(request.semanticType!, request);
    }
    return _inferFromGraphStructure(request);
  }

  /// Risolve nodi impliciti e calcola le posizioni geometriche iniziali
  static Map<String, Offset> resolveImplicitNodes(
    List<String> nodeIds,
    ScenarioRequestV2 request,
  ) {
    final positions = <String, Offset>{};

    // 1. PrioritÃƒÂ  assoluta alle posizioni manuali fornite dall'utente
    if (request.manualPositions != null) {
      positions.addAll(request.manualPositions!);
    }

    // 2. Risoluzione tramite Registry per nodi di sistema noti
    for (final nodeId in nodeIds) {
      if (!positions.containsKey(nodeId) && request.autoResolveNodes) {
        final metadata = GlobalNodeRegistry.get(nodeId);
        if (metadata?.defaultPosition != null) {
          positions[nodeId] = metadata!.defaultPosition!;
        }
      }
    }

    // 3. Calcolo geometrico per i nodi restanti
    final remaining =
        nodeIds.where((id) => !positions.containsKey(id)).toList();
    if (remaining.isNotEmpty) {
      positions.addAll(_generatePositionsForNodes(remaining, request));
    }

    return positions;
  }

  /// Genera etichette automatiche per connessioni basandosi sui ruoli semantici
  static List<String> generateMissingLabels(
    Map<String, List<String>> flow,
    List<String>? existingLabels,
  ) {
    // Se le etichette sono giÃƒÂ  presenti, mantieni quelle originali
    if (existingLabels != null && existingLabels.isNotEmpty) {
      return existingLabels;
    }

    final labels = <String>[];
    flow.forEach((from, targets) {
      for (var to in targets) {
        if (to == 'SUPER_AGENT') {
          labels.add('INGESTION');
        } else if (from == 'SUPER_AGENT') {
          labels.add('COMMAND');
        } else if (from == 'ML_MODEL') {
          labels.add('INFERENCE');
        } else if (from == 'API' || from.contains('SENSOR')) {
          labels.add('TELEMETRY');
        } else {
          labels.add('DATA FLOW');
        }
      }
    });
    return labels;
  }

  /// Inferisce connessioni implicite consultando il registro dei nodi
  static Map<String, List<String>> inferImplicitConnections(
      List<String> nodeIds) {
    final connections = <String, List<String>>{};
    for (final nodeId in nodeIds) {
      final typical = GlobalNodeRegistry.inferConnections(nodeId);
      final relevant = typical.where((t) => nodeIds.contains(t)).toList();
      if (relevant.isNotEmpty) {
        connections[nodeId] = relevant;
      }
    }
    return connections;
  }

  /// Analizza il grafo per calcolare metriche strutturali utili all'ottimizzazione
  static GraphMetrics analyzeGraph(Map<String, List<String>> dataFlow) {
    final nodes = _extractAllNodes(dataFlow);
    final nodeCount = nodes.length;
    final edgeCount = _countEdges(dataFlow);

    final density =
        nodeCount > 1 ? edgeCount / (nodeCount * (nodeCount - 1) / 2) : 0.0;
    final depth = _calculateGraphDepth(dataFlow, nodes);
    final hubs = _identifyHubs(dataFlow, nodes);

    return GraphMetrics(
      nodeCount: nodeCount,
      edgeCount: edgeCount,
      density: density,
      depth: depth,
      hubs: hubs,
    );
  }

  // === PRIVATE HELPERS ===

  static String _inferFromSemanticType(
      String semanticType, ScenarioRequestV2 request) {
    switch (semanticType) {
      case 'real-time':
        return request.focusNode != null ? 'circular' : 'tree';
      case 'batch':
      case 'critical-path':
        return 'layered';
      case 'exploratory':
        return 'force-directed';
      default:
        return 'diamond';
    }
  }

  static String _inferFromGraphStructure(ScenarioRequestV2 request) {
    final metrics = analyzeGraph(request.dataFlow);
    if (metrics.nodeCount <= 5) return 'diamond';
    if (metrics.density > 0.5) {
      return metrics.nodeCount <= 8 ? 'circular' : 'force-directed';
    }
    if (metrics.depth >= metrics.nodeCount * 0.6) return 'layered';
    return 'force-directed';
  }

  /// Genera posizioni utilizzando una distribuzione Ellittica Aspect-Ratio Aware
  static Map<String, Offset> _generatePositionsForNodes(
      List<String> nodes, ScenarioRequestV2 request) {
    final positions = <String, Offset>{};
    final focusNode = request.focusNode;

    // Raggi dinamici: piÃƒÂ¹ nodi ci sono, piÃƒÂ¹ usiamo i bordi
    final double radiusX = nodes.length > 5 ? 0.44 : 0.38;
    final double radiusY = nodes.length > 5 ? 0.40 : 0.32;
    const double centerX = 0.5;
    const double centerY = 0.5;

    final otherNodes = nodes.where((n) => n != focusNode).toList();
    final int count = otherNodes.length;

    // Offset angolare casuale per evitare allineamenti fissi su assi affollati
    double currentAngle = -pi / 2 + (Random().nextDouble() * 0.5);
    final double angleStep = (2 * pi) / count;

    for (var node in otherNodes) {
      // Calcolo con check di collisione iterativo
      for (int attempt = 0; attempt < 8; attempt++) {
        double shift = attempt * 0.25;
        double x = centerX + radiusX * cos(currentAngle + shift);
        double y = centerY + radiusY * sin(currentAngle + shift);

        Offset candidate = Offset(x.clamp(0.1, 0.9), y.clamp(0.1, 0.9));

        // Verifica distanza minima aumentata a 0.25 (25% dello spazio)
        bool tooClose =
            positions.values.any((p) => (candidate - p).distance < 0.25);

        if (!tooClose || attempt == 7) {
          positions[node] = candidate;
          break;
        }
      }
      currentAngle += angleStep;
    }
    return positions;
  }

  static Set<String> _extractAllNodes(Map<String, List<String>> dataFlow) {
    final nodes = <String>{};
    nodes.addAll(dataFlow.keys);
    for (final targets in dataFlow.values) {
      nodes.addAll(targets);
    }
    return nodes;
  }

  static int _countEdges(Map<String, List<String>> dataFlow) {
    return dataFlow.values.fold(0, (sum, targets) => sum + targets.length);
  }

  static int _calculateGraphDepth(
      Map<String, List<String>> dataFlow, Set<String> nodes) {
    if (nodes.isEmpty) return 0;
    final depths = <String, int>{for (var n in nodes) n: 0};

    // Algoritmo di Bellman-Ford semplificato per il calcolo della profonditÃƒÂ  topologica
    for (int i = 0; i < nodes.length; i++) {
      dataFlow.forEach((from, targets) {
        for (final to in targets) {
          if (depths[from]! + 1 > (depths[to] ?? 0)) {
            depths[to] = depths[from]! + 1;
          }
        }
      });
    }
    return depths.values.isNotEmpty ? depths.values.reduce(max) : 0;
  }

  static List<String> _identifyHubs(
      Map<String, List<String>> dataFlow, Set<String> nodes) {
    final degrees = <String, int>{for (var n in nodes) n: 0};

    dataFlow.forEach((from, targets) {
      degrees[from] = (degrees[from] ?? 0) + targets.length;
      for (final to in targets) {
        degrees[to] = (degrees[to] ?? 0) + 1;
      }
    });

    if (degrees.isEmpty) return [];
    final avg = degrees.values.reduce((a, b) => a + b) / degrees.length;
    return degrees.entries
        .where((e) =>
            e.value >
            avg * 1.5) // Hub definiti come 1.5x la media delle connessioni
        .map((e) => e.key)
        .toList();
  }
}

class GraphMetrics {
  final int nodeCount;
  final int edgeCount;
  final double density;
  final int depth;
  final List<String> hubs;

  GraphMetrics({
    required this.nodeCount,
    required this.edgeCount,
    required this.density,
    required this.depth,
    required this.hubs,
  });
}
