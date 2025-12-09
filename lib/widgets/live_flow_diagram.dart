// /lib/widgets/live_flow_diagram.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/mission_control/models.dart';
import 'live_flow_diagram_nodes.dart';
import 'live_flow_diagram_painter.dart'; // Importa il nuovo painter

class LiveFlowDiagram extends StatefulWidget {
  final AnimationController flowController;
  final AnimationController pulseController;
  final Map<String, WorkerStatus> workers;
  final Offset parallaxOffset;

  const LiveFlowDiagram({
    super.key,
    required this.flowController,
    required this.pulseController,
    required this.workers,
    required this.parallaxOffset,
  });

  @override
  State<LiveFlowDiagram> createState() => _LiveFlowDiagramState();
}

class _LiveFlowDiagramState extends State<LiveFlowDiagram> {
  String? _selectedNodeId;

  final connections = const {
    "SUPER_AGENT": [
      "ML_MODEL",
      "LLM",
      "API",
      "METEO",
      "MARINE",
      "SPECIES",
      "MEMORY"
    ],
    "METEO": ["SUPER_AGENT", "API"],
    "MARINE": ["SUPER_AGENT", "API"],
    "SPECIES": ["SUPER_AGENT", "CHROMA"],
    "MEMORY": ["SUPER_AGENT", "SQLITE"],
    "API": ["SUPER_AGENT", "METEO", "MARINE"],
    "SQLITE": ["MEMORY"],
    "CHROMA": ["SPECIES"],
    "ML_MODEL": ["SUPER_AGENT"],
    "LLM": ["SUPER_AGENT"],
  };

  void _onNodeTap(String id) {
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedNodeId = (_selectedNodeId == id) ? null : id;
    });
  }

  bool _isNodeActive(String id) {
    if (_selectedNodeId == null) return true;
    if (_selectedNodeId == id) return true;
    final isConnectedToSelected =
        connections[_selectedNodeId]?.contains(id) ?? false;
    final isSelectedConnectedToNode =
        connections[id]?.contains(_selectedNodeId) ?? false;
    return isConnectedToSelected || isSelectedConnectedToNode;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 520,
          decoration: BoxDecoration(
            color: const Color(0xFF050B14).withOpacity(0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 2)
            ],
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Transform.translate(
                  offset: widget.parallaxOffset * 0.4,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [widget.flowController, widget.pulseController]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: FlowDiagramPainter(
                          flowAnimation: widget.flowController.value,
                          pulseAnimation: widget.pulseController.value,
                          workers: widget.workers,
                          containerSize:
                              Size(constraints.maxWidth, constraints.maxHeight),
                          selectedNode: _selectedNodeId,
                          connectionsMap: connections,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
                Transform.translate(
                  offset: widget.parallaxOffset * 0.8,
                  child: _buildDynamicOverlays(
                      constraints.maxWidth, constraints.maxHeight),
                ),
                if (_selectedNodeId != null)
                  Positioned(
                    top: 20,
                    left: 15,
                    right: 15,
                    child: NodeDetailOverlay(
                        nodeId: _selectedNodeId!,
                        onClose: () => setState(() => _selectedNodeId = null)),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDynamicOverlays(double w, double h) {
    final superAgentY = h * 0.15;
    final dbY = h * 0.5;
    final workerY = h * 0.82;

    return Stack(
      children: [
        Positioned(
            left: 0,
            right: 0,
            top: superAgentY - 50,
            child: Center(
                child: InteractiveNode(
                    id: "SUPER_AGENT",
                    onTap: () => _onNodeTap("SUPER_AGENT"),
                    isDimmed: !_isNodeActive("SUPER_AGENT"),
                    child: AgentNode(
                        icon: Icons.psychology,
                        label: "SUPER AGENT",
                        color: Colors.white,
                        pulseController: widget.pulseController,
                        isActive: true,
                        size: 100)))),
        Positioned(
            left: w * 0.15 - 30,
            top: superAgentY - 20,
            child: InteractiveNode(
                id: "ML_MODEL",
                onTap: () => _onNodeTap("ML_MODEL"),
                isDimmed: !_isNodeActive("ML_MODEL"),
                child: InfraNode(
                    icon: Icons.memory,
                    label: "ML MODEL",
                    color: Colors.cyan))),
        Positioned(
            right: w * 0.15 - 30,
            top: superAgentY - 20,
            child: InteractiveNode(
                id: "LLM",
                onTap: () => _onNodeTap("LLM"),
                isDimmed: !_isNodeActive("LLM"),
                child: InfraNode(
                    icon: Icons.cloud,
                    label: "LLM",
                    color: Colors.purpleAccent))),
        Positioned(
            left: 0,
            right: 0,
            top: h * 0.35 - 25,
            child: Center(
                child: InteractiveNode(
                    id: "API",
                    onTap: () => _onNodeTap("API"),
                    isDimmed: !_isNodeActive("API"),
                    child: InfraNode(
                        icon: Icons.api,
                        label: "API GATEWAY",
                        color: Colors.blueGrey)))),
        Positioned(
            left: w * 0.2 - 35,
            top: dbY - 35,
            child: InteractiveNode(
                id: "SQLITE",
                onTap: () => _onNodeTap("SQLITE"),
                isDimmed: !_isNodeActive("SQLITE"),
                child: DatabaseNode(
                    icon: Icons.storage, label: "SQLITE", color: Colors.blue))),
        Positioned(
            right: w * 0.2 - 35,
            top: dbY - 35,
            child: InteractiveNode(
                id: "CHROMA",
                onTap: () => _onNodeTap("CHROMA"),
                isDimmed: !_isNodeActive("CHROMA"),
                child: DatabaseNode(
                    icon: Icons.hub, label: "CHROMA", color: Colors.purple))),
        Positioned(
          left: 10,
          right: 10,
          top: workerY - 35,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InteractiveNode(
                  id: "METEO",
                  onTap: () => _onNodeTap("METEO"),
                  isDimmed: !_isNodeActive("METEO"),
                  child: WorkerNode(
                      icon: Icons.cloud,
                      label: "Meteo",
                      color: Colors.blue,
                      load: widget.workers['METEO_ANALYST']?.load ?? 0)),
              InteractiveNode(
                  id: "MARINE",
                  onTap: () => _onNodeTap("MARINE"),
                  isDimmed: !_isNodeActive("MARINE"),
                  child: WorkerNode(
                      icon: Icons.waves,
                      label: "Marine",
                      color: Colors.cyan,
                      load: widget.workers['MARINE_SPECIALIST']?.load ?? 0)),
              InteractiveNode(
                  id: "SPECIES",
                  onTap: () => _onNodeTap("SPECIES"),
                  isDimmed: !_isNodeActive("SPECIES"),
                  child: WorkerNode(
                      icon: Icons.pets,
                      label: "Species",
                      color: Colors.teal,
                      load: widget.workers['SPECIES_ADVISOR']?.load ?? 0)),
              InteractiveNode(
                  id: "MEMORY",
                  onTap: () => _onNodeTap("MEMORY"),
                  isDimmed: !_isNodeActive("MEMORY"),
                  child: WorkerNode(
                      icon: Icons.history,
                      label: "Memory",
                      color: Colors.orange,
                      load: widget.workers['MEMORY_RETRIEVER']?.load ?? 0)),
            ],
          ),
        ),
      ],
    );
  }
}
