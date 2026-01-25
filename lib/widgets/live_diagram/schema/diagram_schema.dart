// /lib/widgets/live_diagram/schema/diagram_schema.dart

import 'package:flutter/material.dart';

// =============================================================================
// ENUMS & TYPES
// =============================================================================
enum TriggerType { onStart, onProgress, onComplete }

enum TriggerAction { showLabel, highlightNode, playSound }

enum FlowDirection { forward, reverse, bidirectional }

enum ConnectionType { input, output, bidirectional }

// =============================================================================
// SCENE & PHASE
// =============================================================================

class DiagramScene {
  final String id;
  final String? displayName;
  final Map<String, Offset> nodePositions;
  final List<StoryPhase> phases;
  final List<GhostPath> ghostPaths;
  final ScenarioMetadata? metadata;

  DiagramScene({
    required this.id,
    this.displayName,
    required this.nodePositions,
    required this.phases,
    required this.ghostPaths,
    this.metadata,
  });
}

class ScenarioMetadata {
  final DateTime generatedAt;
  final String moduleType;
  final Map<String, dynamic>? debugInfo;

  const ScenarioMetadata({
    required this.generatedAt,
    required this.moduleType,
    this.debugInfo,
  });
}

class StoryPhase {
  final String id;

  // Doppia gestione: Tempo relativo (Renderer) vs Assoluto (Agent)
  final double startT;
  final double endT;

  final double? startTime; // Per Agent
  final double? duration; // Per Agent
  final String? description;
  final List<PhaseTrigger> triggers;

  final List<VisualElement> elements;

  // Costruttore Ibrido: supporta sia manuale che agent
  StoryPhase({
    required this.id,
    double? startT,
    double? endT,
    this.startTime,
    this.duration,
    this.description,
    this.triggers = const [],
    required this.elements,
  })  : this.startT = startT ?? (startTime != null ? startTime / 12.0 : 0.0),
        this.endT = endT ??
            (duration != null && startTime != null
                ? (startTime + duration) / 12.0
                : 1.0);

  // Metodo copyWith per l'Agent
  StoryPhase copyWith({
    String? id,
    double? startTime,
    double? duration,
    String? description,
    List<PhaseTrigger>? triggers,
    List<VisualElement>? elements,
  }) {
    return StoryPhase(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      triggers: triggers ?? this.triggers,
      elements: elements ?? this.elements,
      startT: (startTime ?? this.startTime ?? 0) / 12.0,
      endT: ((startTime ?? this.startTime ?? 0) +
              (duration ?? this.duration ?? 0)) /
          12.0,
    );
  }
}

class PhaseTrigger {
  final TriggerType type;
  final TriggerAction action;
  final List<String> targetIds;
  final Map<String, dynamic> params;

  const PhaseTrigger({
    required this.type,
    required this.action,
    required this.targetIds,
    this.params = const {},
  });
}

// =============================================================================
// VISUAL ELEMENTS (Unificati)
// =============================================================================

abstract class VisualElement {
  final String type;
  VisualElement(this.type);

  // --- FACTORY METHODS PER L'AGENT ---
  // Questi metodi permettono all'Agent di creare elementi usando una sintassi fluida
  // ma restituiscono le classi concrete che il Renderer già conosce.

  static NeonFlow neonFlow({
    required String id, // ID usato dall'agent, mappato internamente se serve
    required BezierCurve curve,
    required Color color,
    required FlowDirection direction,
    required double speed,
    required String from, // ID del nodo di partenza (es. MARINE)
    required String to, // ID del nodo di arrivo (es. SQLITE)
  }) {
    // Conversione da BezierCurve (Agent) a NeonFlow (Renderer)
    // BezierCurve ha start, control, end.
    // NeonFlow usa controlPointOffset.
    Offset cpOffset = curve.control - (curve.start + curve.end) / 2;

    return NeonFlow(
      fromNode: from,
      toNode: to,
      color: color,
      isCurved: true,
      controlPointOffset: cpOffset,
    );
  }

  static FloatingLabel dataLabel({
    required Offset position,
    required String text,
    required Color color,
  }) {
    // DataLabel dell'agent è assoluta, FloatingLabel del renderer è relativa.
    // Qui creiamo un adattatore. Il renderer dovrà saper gestire 'offset' assoluto se lerp è 0.
    return FloatingLabel(
      text: text,
      anchorNodeA: "DYNAMIC",
      anchorNodeB: "DYNAMIC",
      color: color,
      lerp: 0.0,
      offset: position, // Passiamo la posizione assoluta come offset
    );
  }

  // Metodi placeholder per compatibilità Agent se usati nei builder
  static VisualElement diamondPulse({
    required String nodeId,
    required Color color,
    required Offset center,
    required List<Offset> points,
    required int pulseCount,
  }) =>
      OrbitalEffect(
          targetNode: nodeId, color: color, speed: pulseCount.toDouble());

  static VisualElement particleEffect({
    required Offset center,
    required Color color,
    required int particleCount,
  }) =>
      OrbitalEffect(targetNode: "PARTICLE_SYS", color: color); // Placeholder

  static VisualElement ambientGlow({
    required String nodeId,
    required Color color,
    required double radius,
    required double pulseSpeed,
  }) =>
      OrbitalEffect(targetNode: nodeId, color: color); // Placeholder

  static VisualElement particleTrail({
    required Color color,
    required int count,
    required bool fadeOut,
  }) =>
      OrbitalEffect(targetNode: "TRAIL", color: color); // Placeholder
}

// --- CLASSI CONCRETE (Usate dal Renderer) ---

class NeonFlow extends VisualElement {
  final String fromNode;
  final String toNode;
  final Color color;
  final bool isCurved;
  final Offset? controlPointOffset;
  final Offset? controlPoint2Offset;

  NeonFlow({
    required this.fromNode,
    required this.toNode,
    required this.color,
    this.isCurved = false,
    this.controlPointOffset,
    this.controlPoint2Offset,
  }) : super('neon_flow');
}

class FloatingLabel extends VisualElement {
  final String text;
  final String anchorNodeA;
  final String anchorNodeB;
  final double lerp;
  final Offset offset;
  final Color color;

  FloatingLabel({
    required this.text,
    required this.anchorNodeA,
    required this.anchorNodeB,
    required this.color,
    this.lerp = 0.5,
    this.offset = Offset.zero,
  }) : super('label');
}

class OrbitalEffect extends VisualElement {
  final String targetNode;
  final Color color;
  final double speed;

  OrbitalEffect(
      {required this.targetNode, required this.color, this.speed = 1.0})
      : super('orbital_rings');
}

// --- CLASSI DI SUPPORTO PER L'AGENT ---

class BezierCurve {
  final Offset start, control, end;
  final ConnectionType? type;

  const BezierCurve({
    required this.start,
    required this.control,
    required this.end,
    this.type,
  });

  Map<String, dynamic> toDebugJson() => {
        'start': {'x': start.dx, 'y': start.dy},
        'control': {'x': control.dx, 'y': control.dy},
        'end': {'x': end.dx, 'y': end.dy},
      };
}

class GhostPath {
  final String from;
  final String to;
  final bool curved;
  final Offset? cp;
  final Offset? cp2;

  GhostPath(this.from, this.to, {this.curved = false, this.cp, this.cp2});
}
