// /lib/widgets/live_diagram/logic/diagram_registry_enhanced.dart

import '../schema/diagram_schema.dart';
import '../data/ml_scenario.dart';
import '../ai/diagram_ai_agent.dart';
import '../ai/scenario_request_v2.dart';
import '../ai/models/node_metadata.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// Registry Potenziato con integrazione Agente AI Semantico.
class DiagramRegistryEnhanced {
  static final Map<String, DiagramScene> _scenarios = {
    "ML_MODEL": mlModelScenario,
  };

  static final DiagramAIAgent _agent = DiagramAIAgent();
  static final Map<String, ValidationResult> _validationCache = {};

  /// Recupera scenario esistente
  static DiagramScene? getScenario(String nodeId) => _scenarios[nodeId];

  /// Verifica esistenza scenario
  static bool hasScenario(String nodeId) => _scenarios.containsKey(nodeId);

  /// Registra nuovo scenario (con validazione automatica)
  static bool registerScenario(String nodeId, DiagramScene scene) {
    final validation = _agent.validateScenario(scene);
    _validationCache[nodeId] = validation;

    if (!validation.isValid) {
      print('[Registry] ERRORE: Scenario $nodeId non valido');
      print(validation);
      return false;
    }

    if (validation.warnings.isNotEmpty) {
      print(
          '[Registry] WARNING: Scenario $nodeId ha ${validation.warnings.length} warning');
    }

    _scenarios[nodeId] = scene;
    print('[Registry] Scenario $nodeId registrato con successo');
    return true;
  }

  /// Crea e registra scenario da descrizione LEGACY (backward compatibility)
  static bool createAndRegister(ScenarioRequest request) {
    final requestV2 = ScenarioRequestV2(
      scenarioId: request.scenarioId,
      dataFlow: request.dataFlow,
      layoutTemplate: request.layoutTemplate,
      focusNode: request.focusNode,
      phaseLabels: request.phaseLabels,
    );
    return createAndRegisterV2(requestV2); // Rimosso viewport qui
  }

  /// Crea e registra scenario da ScenarioRequestV2 (semantic-aware)
  static bool createAndRegisterV2(ScenarioRequestV2 request, [Size? viewport]) {
    debugPrint('[Registry] Creazione AI scenario V2: ${request.scenarioId}');
    // Passa viewport se disponibile per calcoli layout adattivi
    final requestWithViewport =
        viewport != null ? request.copyWith(viewportSize: viewport) : request;
    final scene = _agent.createScenarioFromDescription(requestWithViewport);
    return registerScenario(request.scenarioId, scene);
  }

  /// Crea e registra scenario con CHIAVE CUSTOM (per node click support)
  static bool createAndRegisterV2WithKey(
      ScenarioRequestV2 request, String customKey,
      {Size? viewportSize}) {
    final tempAgent = DiagramAIAgent();
    final requestWithViewport = viewportSize != null
        ? request.copyWith(viewportSize: viewportSize)
        : request;
    final scene = tempAgent.createScenarioFromDescription(requestWithViewport);
    _scenarios[customKey] = scene;
    return true;
  }

  /// Ottimizza scenario esistente
  static bool optimizeScenario(
    String nodeId, {
    Size? viewportSize,
    bool optimizeLayout = true,
    bool simplifyPaths = true,
    bool balanceTiming = true,
  }) {
    final original = _scenarios[nodeId];
    if (original == null) {
      return false;
    }

    // PROTEZIONE ML_MODEL: Ripristina layout fisso, NON applica viewport-aware
    if (nodeId == "ML_MODEL") {
      print(
          '[Registry] PROTEZIONE ML_MODEL: Layout fisso, NON applico viewport-aware');
      return true; // Nessuna modifica, mantieni configurazione equilibrata
    }

    // Ricostruisci dataFlow dai ghostPaths per rigenerare le fasi
    final Map<String, List<String>> dataFlow = {};
    for (final ghostPath in original.ghostPaths) {
      if (!dataFlow.containsKey(ghostPath.from)) {
        dataFlow[ghostPath.from] = [];
      }
      if (!dataFlow[ghostPath.from]!.contains(ghostPath.to)) {
        dataFlow[ghostPath.from]!.add(ghostPath.to);
      }
    }

    // Per altri scenari: APPLICA viewport-aware SOLO se viewportSize disponibile
    // Questo rende la disposizione dinamica basata sul numero di elementi
    final optimized = _agent.optimizeExistingScenario(
      original,
      optimizeLayout: optimizeLayout,
      simplifyPaths: simplifyPaths,
      balanceTiming: balanceTiming,
      viewportSize:
          viewportSize, // Per scenari non-ML, guida la disposizione dinamica
      elementCount: original.nodePositions.length + original.ghostPaths.length,
      dataFlow: dataFlow,
    );

    return registerScenario(nodeId, optimized);
  }

  /// Valida tutti gli scenari registrati
  static Map<String, ValidationResult> validateAll() {
    print('[Registry] Validazione completa registry...');
    final results = <String, ValidationResult>{};

    _scenarios.forEach((nodeId, scene) {
      final validation = _agent.validateScenario(scene);
      results[nodeId] = validation;
      _validationCache[nodeId] = validation;

      if (!validation.isValid) {
        print('[Registry] $nodeId: ${validation.errors.length} errori');
      } else if (validation.warnings.isNotEmpty) {
        print('[Registry] $nodeId: ${validation.warnings.length} warning');
      } else {
        print('[Registry] $nodeId: OK');
      }
    });

    return results;
  }

  /// Esporta scenario come codice Dart
  static String exportScenarioCode(String nodeId) {
    final scene = _scenarios[nodeId];
    if (scene == null) {
      return '// Scenario $nodeId non trovato';
    }
    return _agent.exportScenarioAsCode(scene);
  }

  /// Ottiene validazione cached
  static ValidationResult? getValidation(String nodeId) {
    return _validationCache[nodeId];
  }

  /// Lista tutti gli scenari disponibili
  static List<String> listScenarios() {
    return _scenarios.keys.toList()..sort();
  }

  /// Risolvi nodo da GlobalNodeRegistry
  static NodeMetadata? resolveNode(String nodeId) {
    return GlobalNodeRegistry.get(nodeId);
  }

  /// Inferisci connessioni implicite per nodo
  static List<String> inferConnections(String nodeId) {
    return GlobalNodeRegistry.inferConnections(nodeId);
  }

  /// Statistiche registry
  static String getStatistics() {
    final total = _scenarios.length;
    final validated = _validationCache.length;
    final valid = _validationCache.values.where((v) => v.isValid).length;
    final globalNodes = GlobalNodeRegistry.getAllNodeIds().length;

    return '''
=== DIAGRAM REGISTRY STATISTICS ===
Scenari totali: $total
Scenari validati: $validated
Scenari validi: $valid
Scenari con warning: ${validated - valid}
Nodi globali registry: $globalNodes

Scenari disponibili:
${_scenarios.keys.map((k) => ' - $k').join('\n')}
''';
  }

  /// Report dettagliato scenario
  static String getScenarioReport(String nodeId) {
    final scene = _scenarios[nodeId];
    if (scene == null) return 'Scenario non trovato: $nodeId';

    final validation = _validationCache[nodeId];

    return '''
=== SCENARIO REPORT: $nodeId ===
Nodi: ${scene.nodePositions.length}
Ghost Paths: ${scene.ghostPaths.length}
Fasi: ${scene.phases.length}
Validazione: ${validation?.toString() ?? 'Non validato'}
''';
  }

  /// Reset completo (solo per testing)
  static void resetForTesting() {
    _scenarios.clear();
    _validationCache.clear();
    _scenarios["ML_MODEL"] = mlModelScenario;
  }
}

/// Inizializzazione automatica al boot dell'app
class DiagramRegistryInitializer {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    print('\n=== INITIALIZING DIAGRAM REGISTRY V2 (Hybrid Patch) ===\n');

    final patchedPositions =
        Map<String, Offset>.from(mlModelScenario.nodePositions);
    for (var nodeId in patchedPositions.keys) {
      final meta = GlobalNodeRegistry.get(nodeId);
      if (meta?.defaultPosition != null && nodeId == "ML_MODEL") {
        patchedPositions[nodeId] = meta!.defaultPosition!;
      }
    }

    DiagramRegistryEnhanced.registerScenario(
      "ML_MODEL",
      DiagramScene(
        id: mlModelScenario.id,
        nodePositions: patchedPositions,
        ghostPaths: mlModelScenario.ghostPaths,
        phases: mlModelScenario.phases,
      ),
    );

    await _autoGenerateMissingScenarios();
    DiagramRegistryEnhanced.validateAll();
    print('\n${DiagramRegistryEnhanced.getStatistics()}');
    print('\n=== INITIALIZATION COMPLETE ===\n');
    _initialized = true;
  }

  static Future<void> _autoGenerateMissingScenarios() async {
    if (!DiagramRegistryEnhanced.hasScenario('MARINE')) {
      final req = ScenarioRequestV2.realTime(
          scenarioId: 'MARINE_EXPANSION',
          dataFlow: {
            'API': ['MARINE'],
            'MARINE': ['SUPER_AGENT'],
            'SUPER_AGENT': ['SQLITE']
          },
          focusNode: 'MARINE',
          quality: QualityPreset.balanced);
      DiagramRegistryEnhanced.createAndRegisterV2WithKey(req, 'MARINE',
          viewportSize: const Size(800, 520));
    }
    if (!DiagramRegistryEnhanced.hasScenario('METEO')) {
      final req = ScenarioRequestV2.realTime(
          scenarioId: 'METEO_ANALYSIS',
          dataFlow: {
            'API': ['METEO'],
            'METEO': ['SUPER_AGENT'],
            'SUPER_AGENT': ['ML_MODEL']
          },
          focusNode: 'METEO',
          quality: QualityPreset.balanced);
      DiagramRegistryEnhanced.createAndRegisterV2WithKey(req, 'METEO',
          viewportSize: const Size(800, 520));
    }
    if (!DiagramRegistryEnhanced.hasScenario('SPECIES')) {
      final req = ScenarioRequestV2.batch(
          scenarioId: 'SPECIES_LEARNING',
          criticalPath: [
            'CHROMA',
            'SPECIES',
            'ML_MODEL',
            'SUPER_AGENT',
            'SQLITE'
          ],
          quality: QualityPreset.balanced);
      DiagramRegistryEnhanced.createAndRegisterV2WithKey(req, 'SPECIES',
          viewportSize: const Size(800, 520));
    }
  }
}
