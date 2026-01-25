// /lib/widgets/live_diagram/ai/scenario_request_v2.dart

import 'package:flutter/material.dart';

/// Versione avanzata di ScenarioRequest con supporto per inferenza semantica.
/// Supporta tag semantici, categorie nodi e presets di qualità.
class ScenarioRequestV2 {
  final String scenarioId;
  final Map<String, List<String>> dataFlow;

  // === SEMANTIC TAGS ===
  final String?
      semanticType; // 'real-time', 'batch', 'critical-path', 'exploratory'
  final Map<String, String>? nodeCategories; // nodeId -> category override
  final List<String>? criticalPath; // Path ottimizzato per layered layout

  // === QUALITY CONTROL ===
  final QualityPreset qualityPreset;

  // === BACKWARD COMPATIBILITY ===
  final String?
      layoutTemplate; // 'diamond', 'tree', 'circular' (se non usa semanticType)
  final String? focusNode;
  final List<String>? phaseLabels;

  // === ADVANCED OPTIONS ===
  final bool autoResolveNodes; // Usa GlobalNodeRegistry per auto-completare
  final Map<String, Offset>? manualPositions; // Override posizioni specifiche
  final double? preferredSpacing; // Spacing minimo desiderato tra nodi
  final bool
      autoExpandContext; // Espande automaticamente le dipendenze del focus node

  // === VIEWPORT-AWARE LAYOUT (NEW) ===
  final Size? viewportSize; // Dimensioni della finestra per layout adattivo
  late final int _elementCount;

  ScenarioRequestV2({
    required this.scenarioId,
    required this.dataFlow,
    this.semanticType,
    this.nodeCategories,
    this.criticalPath,
    this.qualityPreset = QualityPreset.balanced,
    this.layoutTemplate,
    this.focusNode,
    this.phaseLabels,
    this.autoResolveNodes = true,
    this.manualPositions,
    this.preferredSpacing,
    this.autoExpandContext = false,
    this.viewportSize,
  }) {
    // Conteggio automatico elementi
    final nodeCount = <String>{
      ...dataFlow.keys,
      ...dataFlow.values.expand((list) => list)
    }.length;
    final edgeCount =
        dataFlow.values.fold<int>(0, (sum, targets) => sum + targets.length);
    _elementCount = nodeCount + edgeCount;
  }

  /// Getter elementCount
  int get elementCount => _elementCount;

  /// Crea una copia con parametri opzionali modificati
  ScenarioRequestV2 copyWith({
    String? scenarioId,
    Map<String, List<String>>? dataFlow,
    String? semanticType,
    Map<String, String>? nodeCategories,
    List<String>? criticalPath,
    QualityPreset? qualityPreset,
    String? layoutTemplate,
    String? focusNode,
    List<String>? phaseLabels,
    bool? autoResolveNodes,
    Map<String, Offset>? manualPositions,
    double? preferredSpacing,
    bool? autoExpandContext,
    Size? viewportSize,
  }) {
    return ScenarioRequestV2(
      scenarioId: scenarioId ?? this.scenarioId,
      dataFlow: dataFlow ?? this.dataFlow,
      semanticType: semanticType ?? this.semanticType,
      nodeCategories: nodeCategories ?? this.nodeCategories,
      criticalPath: criticalPath ?? this.criticalPath,
      qualityPreset: qualityPreset ?? this.qualityPreset,
      layoutTemplate: layoutTemplate ?? this.layoutTemplate,
      focusNode: focusNode ?? this.focusNode,
      phaseLabels: phaseLabels ?? this.phaseLabels,
      autoResolveNodes: autoResolveNodes ?? this.autoResolveNodes,
      manualPositions: manualPositions ?? this.manualPositions,
      preferredSpacing: preferredSpacing ?? this.preferredSpacing,
      autoExpandContext: autoExpandContext ?? this.autoExpandContext,
      viewportSize: viewportSize ?? this.viewportSize,
    );
  }

  /// Factory per scenari real-time (sensori → orchestrator)
  factory ScenarioRequestV2.realTime({
    required String scenarioId,
    required Map<String, List<String>> dataFlow,
    String? focusNode,
    QualityPreset quality = QualityPreset.fast,
  }) {
    return ScenarioRequestV2(
      scenarioId: scenarioId,
      dataFlow: dataFlow,
      semanticType: 'real-time',
      focusNode: focusNode,
      qualityPreset: quality,
    );
  }

  /// Factory per scenari batch (pipeline lineare)
  factory ScenarioRequestV2.batch({
    required String scenarioId,
    required List<String> criticalPath,
    Map<String, List<String>>? additionalFlow,
    QualityPreset quality = QualityPreset.balanced,
  }) {
    final flow = <String, List<String>>{};
    for (int i = 0; i < criticalPath.length - 1; i++) {
      flow[criticalPath[i]] = [criticalPath[i + 1]];
    }
    if (additionalFlow != null) {
      flow.addAll(additionalFlow);
    }

    return ScenarioRequestV2(
      scenarioId: scenarioId,
      dataFlow: flow,
      semanticType: 'batch',
      criticalPath: criticalPath,
      qualityPreset: quality,
    );
  }

  /// Factory per scenari esplorativi (grafo complesso)
  factory ScenarioRequestV2.exploratory({
    required String scenarioId,
    required Map<String, List<String>> dataFlow,
    QualityPreset quality = QualityPreset.premium,
  }) {
    return ScenarioRequestV2(
      scenarioId: scenarioId,
      dataFlow: dataFlow,
      semanticType: 'exploratory',
      qualityPreset: quality,
    );
  }

  /// Converte a ScenarioRequest legacy (backward compatibility)
  ScenarioRequest toLegacy() {
    return ScenarioRequest(
      scenarioId: scenarioId,
      dataFlow: dataFlow,
      layoutTemplate: layoutTemplate,
      focusNode: focusNode,
      phaseLabels: phaseLabels,
    );
  }
}

/// Livelli di qualità per ottimizzazione
enum QualityPreset {
  fast, // 10 iterazioni, no crossing optimization, < 50ms
  balanced, // 50 iterazioni, crossing check base, < 150ms
  premium; // 200 iterazioni, full geometry optimization, < 500ms

  int get maxIterations {
    switch (this) {
      case QualityPreset.fast:
        return 10;
      case QualityPreset.balanced:
        return 50;
      case QualityPreset.premium:
        return 200;
    }
  }

  bool get enableCrossingOptimization {
    return this != QualityPreset.fast;
  }

  bool get enableFullGeometry {
    return this == QualityPreset.premium;
  }
}

/// Request legacy (backward compatibility)
class ScenarioRequest {
  final String scenarioId;
  final Map<String, List<String>> dataFlow;
  final String? layoutTemplate;
  final String? focusNode;
  final List<String>? phaseLabels;

  ScenarioRequest({
    required this.scenarioId,
    required this.dataFlow,
    this.layoutTemplate,
    this.focusNode,
    this.phaseLabels,
  });
}

/// Template topologico
class TopologyTemplate {
  final String name;
  final bool centerNode;
  final double satelliteRadius;
  final double verticalSpread;

  const TopologyTemplate({
    required this.name,
    required this.centerNode,
    required this.satelliteRadius,
    required this.verticalSpread,
  });

  /// Copia adattando i parametri ai valori viewport-aware
  TopologyTemplate copyWithAdaptive(dynamic adaptiveParams) {
    return TopologyTemplate(
      name: name,
      centerNode: centerNode,
      satelliteRadius: adaptiveParams.satelliteRadius,
      verticalSpread: adaptiveParams.verticalSpread,
    );
  }
}

/// Risultato validazione
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== VALIDATION RESULT ===');
    buffer.writeln('Status: ${isValid ? "✓ VALID" : "✗ INVALID"}');

    if (errors.isNotEmpty) {
      buffer.writeln('\nERRORS (${errors.length}):');
      for (final err in errors) {
        buffer.writeln('  • $err');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('\nWARNINGS (${warnings.length}):');
      for (final warn in warnings) {
        buffer.writeln('  • $warn');
      }
    }

    return buffer.toString();
  }
}
