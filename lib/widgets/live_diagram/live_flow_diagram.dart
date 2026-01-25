// /lib/widgets/live_diagram/live_flow_diagram.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:pesca_app/screens/mission_control/models.dart';

// Moduli interni
import 'logic/diagram_topology.dart';
import 'logic/diagram_registry.dart';
import 'schema/diagram_schema.dart';
import 'components/diagram_nodes.dart';
import 'components/diagram_overlay_builder.dart';
import 'painters/flow_diagram_painter.dart';
import 'logic/diagram_registry_enhanced.dart';

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

class _LiveFlowDiagramState extends State<LiveFlowDiagram>
    with SingleTickerProviderStateMixin {
  String? _selectedNodeId;
  late AnimationController _mlStoryController;
  bool _isMlStoryActive = false;
  DiagramScene? _activeScene;
  Size? _lastLayoutSize;

  // Mappa completa delle connessioni per il dimming standard
  final connections = const {
    "SUPER_AGENT": [
      "ML_MODEL",
      "LLM",
      "API",
      "WEATHER",
      "MARINE",
      "SPECIES",
      "MEMORY"
    ],
    "WEATHER": ["SUPER_AGENT", "API"],
    "MARINE": ["SUPER_AGENT", "API"],
    "SQLITE": ["MEMORY", "SUPER_AGENT"],
    "SPECIES": ["SUPER_AGENT", "CHROMA"],
    "MEMORY": ["SUPER_AGENT", "SQLITE"],
    "API": ["SUPER_AGENT", "WEATHER", "MARINE"],
    "CHROMA": ["SPECIES"],
    "ML_MODEL": ["SUPER_AGENT"],
    "LLM": ["SUPER_AGENT"],
  };

  @override
  void initState() {
    super.initState();
    _mlStoryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _mlStoryController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isMlStoryActive) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isMlStoryActive) {
            _mlStoryController.forward(from: 0.15);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mlStoryController.dispose();
    super.dispose();
  }

  void _onNodeTap(String id) {
    HapticFeedback.heavyImpact();

    // 1. Ottimizza scenario PRIMA di prenderlo
    if (_lastLayoutSize != null) {
      DiagramRegistryEnhanced.optimizeScenario(id,
          viewportSize: _lastLayoutSize);
    }

    // 2. Leggi scenario DOPO ottimizzazione
    final enhancedScenario = DiagramRegistryEnhanced.getScenario(id);
    final standardScenario = DiagramRegistry.getScenario(id);

    // LOG DI DEBUG RICHIESTI
    print('[DEBUG] Clicked: $id');
    print('[DEBUG] Enhanced: ${enhancedScenario?.id}');
    print('[DEBUG] Standard: ${standardScenario?.id}');
    if (_lastLayoutSize != null) {
      print(
          '[DEBUG] Viewport Size: ${_lastLayoutSize!.width}x${_lastLayoutSize!.height}');
    }

    setState(() {
      // 2. Controllo chiusura (se clicco sul nodo giÃƒÆ’Ã‚Â  attivo in modalitÃƒÆ’Ã‚Â  storia)
      if (_isMlStoryActive && _selectedNodeId == id) {
        _resetStory();
        return; // Esco subito
      }

      // 3. Gestione Scenari (Enhanced ha la prioritÃƒÆ’Ã‚Â )
      final sceneToActivate = enhancedScenario ?? standardScenario;

      if (sceneToActivate != null) {
        _selectedNodeId = id;
        _activeScene = sceneToActivate;

        // ÃƒÂ¢Ã…â€œÃ‚Â¨ RESET + RESTART dell'animazione
        _mlStoryController.reset();
        _isMlStoryActive = true;
        _mlStoryController.forward(from: 0.0);

        print(
            '[DEBUG] ModalitÃƒÆ’Ã‚Â  Storia ATTIVATA per: ${sceneToActivate.id}');
      }
      // 4. Nodo Standard o Reset (se non c'ÃƒÆ’Ã‚Â¨ scenario)
      else {
        _resetStory();
        // Toggle del popup standard: se clicco lo stesso nodo lo chiudo (null), altrimenti lo apro
        _selectedNodeId = (_selectedNodeId == id) ? null : id;

        print(
            '[DEBUG] Nodo Standard rilevato. ID selezionato: $_selectedNodeId');
      }
    });
  }

  void _resetStory() {
    _isMlStoryActive = false;
    _mlStoryController.reset();
    _selectedNodeId = null;
    _activeScene = null;
  }

  bool _isNodeActive(String id) {
    // Dimming Data-Driven: se c'ÃƒÆ’Ã‚Â¨ una scena attiva, chiediamo a lei chi deve restare acceso
    if (_isMlStoryActive && _activeScene != null) {
      return _activeScene!.nodePositions.containsKey(id);
    }
    // Dimming Standard
    if (_selectedNodeId == null) return true;
    return _selectedNodeId == id ||
        (connections[_selectedNodeId]?.contains(id) ?? false);
  }

  /// ÃƒÂ¢Ã…â€œÃ‚Â¨ METODO PUBBLICO per refresh (chiamato da parent via GlobalKey)
  void refreshScene() {
    // ÃƒÂ¢Ã…â€œÃ‚Â¨ Forza reset completo per ricaricare scenari
    setState(() {
      if (_selectedNodeId != null) {
        // Ricarica scenario corrente da registry
        final updatedScene =
            DiagramRegistryEnhanced.getScenario(_selectedNodeId!);

        if (updatedScene != null) {
          _activeScene = updatedScene;

          // Reset + restart animazione
          _mlStoryController.reset();
          _isMlStoryActive = true;
          _mlStoryController.forward(from: 0.0);
        }
      }
    });
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
            color: const Color(0xFF050B14).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.08),
                blurRadius: 40,
                spreadRadius: 2,
              )
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              _lastLayoutSize =
                  Size(constraints.maxWidth, constraints.maxHeight);
              final topo = DiagramTopology(
                  Size(constraints.maxWidth, constraints.maxHeight));

              return Stack(
                children: [
                  // 1. LAYER DISEGNO (Linee Neon + Storia)
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [widget.flowController, _mlStoryController]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: FlowDiagramPainter(
                          flowAnimation: widget.flowController.value,
                          pulseAnimation: widget.pulseController.value,
                          mlStoryAnimation: _mlStoryController.value,
                          isMlStoryActive: _isMlStoryActive,
                          workers: widget.workers,
                          connectionsMap: connections,
                          topo: topo,
                          selectedNode: _selectedNodeId,
                          activeScene: _activeScene,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),

                  // 2. LAYER INTERATTIVO (Icone/Widget)
                  Transform.translate(
                    offset: widget.parallaxOffset * 0.8,
                    child: AnimatedBuilder(
                      animation: _mlStoryController,
                      builder: (context, _) {
                        return DiagramOverlayBuilder(
                          topo: topo,
                          mlStoryValue: _mlStoryController.value,
                          pulseController: widget.pulseController,
                          workers: widget.workers,
                          onNodeTap: _onNodeTap,
                          isNodeActive: _isNodeActive,
                          activeScene: _activeScene,
                        );
                      },
                    ),
                  ),

                  // 3. POPUP STANDARD (Solo se non siamo in modalitÃƒÆ’Ã‚Â  storia)
                  if (_selectedNodeId != null && !_isMlStoryActive)
                    Positioned(
                      top: 20,
                      left: 15,
                      right: 15,
                      child: NodeDetailOverlay(
                        nodeId: _selectedNodeId!,
                        onClose: () => setState(() => _selectedNodeId = null),
                      ),
                    )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
