import 'package:flutter/material.dart';
import '../schema/diagram_schema.dart';

final mlModelScenario = DiagramScene(
  id: "ML_EXPANSION",
  nodePositions: {
    // LAYOUT FISSO RICHIESTO
    "ML_MODEL": const Offset(0.50, 0.05), // Alto Centro
    "WEATHER": const Offset(0.05, 0.35), // Alto Sinistra
    "SUPER_AGENT": const Offset(0.95, 0.60), // Destra (Spostato come richiesto)
    "SQLITE": const Offset(0.50, 0.80), // Basso Centro
    "USER_FEEDBACK":
        const Offset(0.15, 0.95), // Basso Sinistra (Spostato come richiesto)
  },
  ghostPaths: [
    GhostPath("WEATHER", "ML_MODEL", curved: true, cp: const Offset(-120, 0)),
    // Curva adattata per SuperAgent a destra
    GhostPath("ML_MODEL", "SUPER_AGENT",
        curved: true, cp: const Offset(80, 20)),
    GhostPath("ML_MODEL", "SQLITE", curved: true, cp: const Offset(-80, 0)),
    GhostPath("SQLITE", "ML_MODEL", curved: true, cp: const Offset(120, 0)),
    // Curva adattata per Feedback a sinistra (verso DX)
    //GhostPath("USER_FEEDBACK", "SQLITE",
    //    curved: true, cp: const Offset(40, -40)),
  ],
  phases: [
    // --- PHASE 1: INPUT STREAM ---
    StoryPhase(id: "input", startT: 0.15, endT: 0.40, elements: [
      NeonFlow(
        fromNode: "WEATHER",
        toNode: "ML_MODEL",
        color: Colors.blueAccent,
        isCurved: true,
        controlPointOffset: const Offset(-120, 0),
      ),
      FloatingLabel(
          text: "RAW DATA FETCH",
          anchorNodeA: "WEATHER",
          anchorNodeB: "ML_MODEL",
          color: Colors.blueAccent,
          offset: const Offset(-40, -30)),
    ]),

    // --- PHASE 1.5: ORBITAL RINGS ---
    StoryPhase(id: "processing", startT: 0.35, endT: 0.50, elements: [
      OrbitalEffect(
          targetNode: "ML_MODEL", color: Colors.cyanAccent, speed: 8.0)
    ]),

    // --- PHASE 2: SCORE & STORE ---
    StoryPhase(id: "output", startT: 0.42, endT: 0.65, elements: [
      NeonFlow(
        fromNode: "ML_MODEL",
        toNode: "SUPER_AGENT",
        color: Colors.cyanAccent,
        isCurved: true,
        controlPointOffset: const Offset(80, 20),
      ),
      FloatingLabel(
          text: "SCORE: 7.8",
          anchorNodeA: "ML_MODEL",
          anchorNodeB: "SUPER_AGENT",
          color: Colors.cyanAccent,
          lerp: 0.45,
          offset: const Offset(10, -30)),
      NeonFlow(
          fromNode: "ML_MODEL",
          toNode: "SQLITE",
          color: Colors.orangeAccent,
          isCurved: true,
          controlPointOffset: const Offset(-80, 0)),
      FloatingLabel(
          text: "PREDICTION SAVED",
          anchorNodeA: "ML_MODEL",
          anchorNodeB: "SQLITE",
          color: Colors.orangeAccent,
          lerp: 0.60,
          offset: const Offset(-90, 10)),
    ]),

    // --- PHASE 3: FEEDBACK ---
    StoryPhase(id: "feedback", startT: 0.60, endT: 0.87, elements: [
      NeonFlow(
        fromNode: "USER_FEEDBACK",
        toNode: "SQLITE",
        color: Colors.pinkAccent,
        isCurved: true,
        controlPointOffset: const Offset(-40, 10),
      ),
      FloatingLabel(
          text: "REALITY CHECK",
          anchorNodeA: "USER_FEEDBACK",
          anchorNodeB: "SQLITE",
          color: Colors.pinkAccent,
          offset: const Offset(-58, -8)),
    ]),

    // --- PHASE 4: LEARNING ---
    StoryPhase(id: "retrain", startT: 0.80, endT: 1.00, elements: [
      NeonFlow(
          fromNode: "SQLITE",
          toNode: "ML_MODEL",
          color: Colors.greenAccent,
          isCurved: true,
          controlPointOffset: const Offset(120, 0)),
      FloatingLabel(
          text: "RETRAINING",
          anchorNodeA: "SQLITE",
          anchorNodeB: "ML_MODEL",
          color: Colors.greenAccent,
          offset: const Offset(20, 0)),
    ])
  ],
);
