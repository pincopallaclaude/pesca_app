import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pesca_app/screens/mission_control/models.dart';
import '../logic/diagram_topology.dart';
import '../schema/diagram_schema.dart';
import '../components/diagram_nodes.dart';

class DiagramOverlayBuilder extends StatelessWidget {
  final DiagramTopology topo;
  final double mlStoryValue;
  final AnimationController pulseController;
  final Map<String, WorkerStatus> workers;
  final Function(String) onNodeTap;
  final bool Function(String) isNodeActive;
  final DiagramScene? activeScene;

  const DiagramOverlayBuilder({
    super.key,
    required this.topo,
    required this.mlStoryValue,
    required this.pulseController,
    required this.workers,
    required this.onNodeTap,
    required this.isNodeActive,
    this.activeScene,
  });

  Offset _toAbsolute(Offset normalized) {
    const double padding = 45.0;
    final double safeW = topo.size.width - (padding * 2);
    final double safeH = topo.size.height - (padding * 2);
    return Offset(
      padding + (normalized.dx * safeW),
      padding + (normalized.dy * safeH),
    );
  }

  Offset _getNodePosition(Offset standardPos, String nodeId) {
    final t = mlStoryValue;
    final moveT =
        const Interval(0.0, 0.1, curve: Curves.easeInOut).transform(t);

    if (activeScene != null && activeScene!.nodePositions.containsKey(nodeId)) {
      final scenarioPos = activeScene!.nodePositions[nodeId]!;
      final targetPos = _toAbsolute(scenarioPos);
      if (moveT >= 1.0) return targetPos;
      return Offset.lerp(standardPos, targetPos, moveT)!;
    }
    return standardPos;
  }

  Offset _getSpawnPosition(String nodeId, Offset defaultOrigin) {
    final t = mlStoryValue;
    final moveT =
        const Interval(0.0, 0.1, curve: Curves.easeInOut).transform(t);

    if (activeScene != null && activeScene!.nodePositions.containsKey(nodeId)) {
      final scenarioPos = activeScene!.nodePositions[nodeId]!;
      final targetPos = _toAbsolute(scenarioPos);
      return Offset.lerp(defaultOrigin, targetPos, moveT)!;
    }
    return defaultOrigin;
  }

  Offset _getExitPosition(Offset standardPos, Offset exitPos) {
    final t = mlStoryValue;
    final moveT =
        const Interval(0.0, 0.1, curve: Curves.easeOutCubic).transform(t);
    return Offset.lerp(standardPos, exitPos, moveT)!;
  }

  @override
  Widget build(BuildContext context) {
    final t = mlStoryValue;
    final moveT =
        const Interval(0.0, 0.1, curve: Curves.easeOutCubic).transform(t);
    final stdOp = (1.0 - moveT * 2.0).clamp(0.0, 1.0);
    final ignoreStd = t > 0.05;

    // DEBUG SICURO (Concatenazione)
    if (t == 0.0) {
      // ignore: avoid_print
    }

    return Stack(
      children: [
        // === NODI PROTAGONISTI (Sempre interattivi) ===
        _buildPositionedNode(
          'SUPER_AGENT',
          _getNodePosition(topo.stdSuperPos, "SUPER_AGENT"),
          50,
          AgentNode(
            icon: Icons.psychology,
            label: "SUPER AGENT",
            color: Colors.white,
            pulseController: pulseController,
            isActive: true,
            size: 100,
          ),
        ),
        _buildPositionedNode(
          'ML_MODEL',
          _getNodePosition(topo.stdMlPos, "ML_MODEL"),
          30,
          InfraNode(icon: Icons.memory, label: "ML MODEL", color: Colors.cyan),
        ),
        _buildPositionedNode(
          'SQLITE',
          _getNodePosition(topo.stdSqlitePos, "SQLITE"),
          35,
          DatabaseNode(
              icon: Icons.storage, label: "SQLITE", color: Colors.blue),
        ),

        // === NODI DINAMICI (Scenario) ===
        if (activeScene != null)
          ...activeScene!.nodePositions.keys.map((nodeId) {
            if (['SUPER_AGENT', 'ML_MODEL', 'SQLITE'].contains(nodeId))
              return const SizedBox.shrink();

            final nodePos = _getSpawnPosition(nodeId, topo.stdApiPos);

            // Logica Visibility
            double opacity = 0.0;
            if (nodeId == 'USER_FEEDBACK') {
              opacity = (t > 0.45) ? ((t - 0.45) / 0.2).clamp(0.0, 1.0) : 0.0;
            } else if (activeScene != null &&
                activeScene!.nodePositions.containsKey(nodeId)) {
              opacity = (t * 5.0).clamp(0.0, 1.0);
            } else {
              opacity = 1.0;
            }

            return Positioned(
              key: ValueKey(nodeId + '_node'),
              left: nodePos.dx - 30,
              top: nodePos.dy - 30,
              child: Opacity(
                opacity: opacity,
                // Usiamo GestureDetector diretto sul Container per i nodi dinamici
                child: GestureDetector(
                  onTap: () {
                    // ignore: avoid_print
                    print('>>> TOUCH: ' + nodeId);
                    onNodeTap(nodeId);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: _buildDynamicNode(nodeId),
                ),
              ),
            );
          }).toList(),

        // === NODI STANDARD (Fading out) ===
        IgnorePointer(
          ignoring: ignoreStd,
          child: Opacity(
            opacity: stdOp,
            child: Stack(
              children: [
                _buildPositionedNode(
                    'LLM',
                    _getExitPosition(topo.stdLlmPos, topo.exitTop),
                    30,
                    InfraNode(
                        icon: Icons.cloud,
                        label: "LLM",
                        color: Colors.purpleAccent)),
                _buildPositionedNode(
                    'API',
                    _getExitPosition(topo.stdApiPos, topo.exitTop),
                    30,
                    InfraNode(
                        icon: Icons.api, label: "API", color: Colors.blueGrey)),
                _buildPositionedNode(
                    'CHROMA',
                    _getExitPosition(topo.stdChromaPos, topo.exitBottom),
                    35,
                    DatabaseNode(
                        icon: Icons.hub,
                        label: "CHROMA",
                        color: Colors.purple)),
                _buildWorkerNode(topo.stdMeteoPos, topo.exitBottom, "WEATHER",
                    Icons.cloud, Colors.blue, "METEO_ANALYST"),
                _buildWorkerNode(topo.stdMarinePos, topo.exitBottom, "MARINE",
                    Icons.waves, Colors.cyan, "MARINE_SPECIALIST"),
                _buildWorkerNode(topo.stdSpeciesPos, topo.exitBottom, "SPECIES",
                    Icons.pets, Colors.teal, "SPECIES_ADVISOR"),
                _buildWorkerNode(topo.stdMemoryPos, topo.exitBottom, "MEMORY",
                    Icons.history, Colors.orange, "MEMORY_RETRIEVER"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // FIX: Rimuoviamo il GestureDetector esterno e passiamo onTap a InteractiveNode
  Widget _buildPositionedNode(
      String id, Offset position, double radius, Widget child) {
    return Positioned(
      key: ValueKey(id),
      left: position.dx - radius,
      top: position.dy - radius,
      child: InteractiveNode(
        id: id,
        onTap: () {
          // ignore: avoid_print
          print('>>> TOUCH: ' + id);
          onNodeTap(id);
        },
        isDimmed: !isNodeActive(id),
        child: child,
      ),
    );
  }

  Widget _buildWorkerNode(Offset standardPos, Offset exitPos, String id,
      IconData icon, Color color, String workerKey) {
    final position = Offset.lerp(
        standardPos, exitPos, mlStoryValue < 0.1 ? mlStoryValue * 10 : 1.0)!;
    return _buildPositionedNode(
        id,
        position,
        30,
        WorkerNode(
            icon: icon,
            label: id,
            color: color,
            load: workers[workerKey]?.load ?? 0));
  }

  Widget _buildDynamicNode(String nodeId) {
    final nodeConfig = _getNodeConfig(nodeId);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F172A).withOpacity(0.9),
        border: Border.all(color: nodeConfig['color'] as Color, width: 2),
        boxShadow: [
          BoxShadow(
              color: (nodeConfig['color'] as Color).withOpacity(0.3),
              blurRadius: 12)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(nodeConfig['icon'] as IconData,
              color: nodeConfig['color'] as Color, size: 24),
          const SizedBox(height: 2),
          Text(
              nodeId == 'USER_FEEDBACK'
                  ? 'USER'
                  : (nodeId.length > 8
                      ? '${nodeId.substring(0, 6)}...'
                      : nodeId),
              style: TextStyle(
                  color: nodeConfig['color'] as Color,
                  fontSize: 8,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Map<String, dynamic> _getNodeConfig(String nodeId) {
    final configs = {
      'MARINE': {'icon': Icons.waves, 'color': Colors.blueAccent},
      'METEO': {'icon': Icons.cloud, 'color': Colors.lightBlueAccent},
      'SPECIES': {'icon': Icons.pets, 'color': Colors.greenAccent},
      'API': {'icon': Icons.api, 'color': Colors.orangeAccent},
      'MEMORY': {'icon': Icons.history, 'color': Colors.amberAccent},
      'CHROMA': {'icon': Icons.hub, 'color': Colors.pinkAccent},
      'WEATHER': {'icon': Icons.cloud, 'color': Colors.lightBlueAccent},
      'USER_FEEDBACK': {'icon': Icons.thumb_up_alt, 'color': Colors.pinkAccent},
    };
    return configs[nodeId] ?? {'icon': Icons.circle, 'color': Colors.grey};
  }
}
