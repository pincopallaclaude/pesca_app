// /lib/widgets/live_diagram/examples/ai_agent_example.dart

import 'package:flutter/material.dart';
import '../ai/diagram_ai_agent.dart';
import '../ai/scenario_request_v2.dart';
import '../logic/diagram_registry_enhanced.dart';

/// Esempio completo di utilizzo dell'Agente AI V2
class DiagramAIAgentExample {
  final DiagramAIAgent agent = DiagramAIAgent();

  /// ESEMPIO 1: Creazione nuovo scenario "MARINE" con V2
  void exampleCreateMarineScenario() {
    print('\n=== ESEMPIO 1: Creazione Scenario MARINE (V2) ===\n');

    final request = ScenarioRequestV2.realTime(
      scenarioId: 'MARINE_EXPANSION',
      dataFlow: {
        'API': ['MARINE'],
        'MARINE': ['SUPER_AGENT'],
        'SUPER_AGENT': ['SQLITE'],
        'SQLITE': ['MARINE'],
      },
      focusNode: 'MARINE',
      quality: QualityPreset.balanced,
    );

    final marineScenario = agent.createScenarioFromDescription(request);
    final validation = agent.validateScenario(marineScenario);
    print(validation);

    if (validation.isValid) {
      final code = agent.exportScenarioAsCode(marineScenario);
      print('\n--- CODICE GENERATO ---\n');
      print(code);
    }
  }

  /// ESEMPIO 2: Ottimizzazione scenario esistente
  void exampleOptimizeExistingScenario() {
    print('\n=== ESEMPIO 2: Ottimizzazione ML Scenario ===\n');

    final mlScenario = DiagramRegistryEnhanced.getScenario('ML_MODEL');

    if (mlScenario != null) {
      final optimized = agent.optimizeExistingScenario(
        mlScenario,
        optimizeLayout: true,
        simplifyPaths: true,
        balanceTiming: true,
      );

      final validation = agent.validateScenario(optimized);
      print(validation);

      print('\n--- METRICHE CONFRONTO ---');
      print(
          'Ghost Paths: ${mlScenario.ghostPaths.length} → ${optimized.ghostPaths.length}');
      print('Fasi: ${mlScenario.phases.length} → ${optimized.phases.length}');
    }
  }

  /// ESEMPIO 3: Creazione scenario complesso multi-agente con Batch
  void exampleComplexMultiAgentScenario() {
    print('\n=== ESEMPIO 3: Scenario Multi-Agente Complesso (Batch) ===\n');

    final request = ScenarioRequestV2.batch(
      scenarioId: 'FULL_ANALYSIS',
      criticalPath: [
        'METEO',
        'MARINE',
        'SPECIES',
        'SUPER_AGENT',
        'ML_MODEL',
        'SQLITE',
        'MEMORY'
      ],
      quality: QualityPreset.premium,
    );

    final complexScenario = agent.createScenarioFromDescription(request);
    final validation = agent.validateScenario(complexScenario);
    print(validation);

    print('\n--- STATISTICHE SCENARIO ---');
    print('Nodi coinvolti: ${complexScenario.nodePositions.length}');
    print('Connessioni: ${complexScenario.ghostPaths.length}');
    print('Fasi: ${complexScenario.phases.length}');
  }

  /// ESEMPIO 4: Ottimizzazione topologica V2 con quality presets
  void exampleCustomTopologyOptimization() {
    print('\n=== ESEMPIO 4: Ottimizzazione Topologica V2 ===\n');

    final nodes = [
      'SUPER_AGENT',
      'ML_MODEL',
      'METEO',
      'MARINE',
      'SPECIES',
      'MEMORY',
      'SQLITE',
      'CHROMA',
    ];

    for (final template in ['diamond', 'tree', 'circular', 'force-directed']) {
      print('\n--- Layout: $template ---');

      final positions = agent.optimizeTopologyV2(
        nodes: nodes,
        template: template,
        focusNode: 'SUPER_AGENT',
        qualityPreset: QualityPreset.balanced,
      );

      print('Nodi posizionati: ${positions.length}');
      print('Spazio utilizzato: ${_getDistributionMetrics(positions)}');
    }
  }

  /// ESEMPIO 5: Pipeline completa con validazione iterativa
  void exampleFullPipeline() {
    print('\n=== ESEMPIO 5: Pipeline Completa V2 ===\n');

    final request = ScenarioRequestV2.exploratory(
      scenarioId: 'SPECIES_LEARNING',
      dataFlow: {
        'CHROMA': ['SPECIES'],
        'SPECIES': ['ML_MODEL'],
        'ML_MODEL': ['SUPER_AGENT'],
        'SUPER_AGENT': ['SQLITE'],
      },
      quality: QualityPreset.premium,
    );

    var scenario = agent.createScenarioFromDescription(request);
    print('✓ Scenario generato');

    var validation = agent.validateScenario(scenario);
    print('\nValidazione iniziale:');
    print('  Errori: ${validation.errors.length}');
    print('  Warning: ${validation.warnings.length}');

    if (validation.warnings.isNotEmpty) {
      print('\n✓ Applicazione ottimizzazioni...');
      scenario = agent.optimizeExistingScenario(scenario);
      validation = agent.validateScenario(scenario);
      print('  Errori: ${validation.errors.length}');
      print('  Warning: ${validation.warnings.length}');
    }

    if (validation.isValid) {
      print('\n✓ Scenario valido! Export codice...');
      final code = agent.exportScenarioAsCode(scenario);
      print('✓ Pipeline completata con successo!');
      print('Codice generato: ${code.length} caratteri');
    }
  }

  String _getDistributionMetrics(Map<String, Offset> positions) {
    final xValues = positions.values.map((p) => p.dx);
    final yValues = positions.values.map((p) => p.dy);

    final xSpread = xValues.reduce((a, b) => a > b ? a : b) -
        xValues.reduce((a, b) => a < b ? a : b);
    final ySpread = yValues.reduce((a, b) => a > b ? a : b) -
        yValues.reduce((a, b) => a < b ? a : b);

    return 'X: ${(xSpread * 100).toStringAsFixed(0)}%, Y: ${(ySpread * 100).toStringAsFixed(0)}%';
  }
}

void main() {
  final examples = DiagramAIAgentExample();
  examples.exampleCreateMarineScenario();
  examples.exampleOptimizeExistingScenario();
  examples.exampleComplexMultiAgentScenario();
  examples.exampleCustomTopologyOptimization();
  examples.exampleFullPipeline();
}
