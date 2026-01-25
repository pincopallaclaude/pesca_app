// /lib/widgets/live_diagram/logic/diagram_registry.dart

import '../schema/diagram_schema.dart';
import '../data/ml_scenario.dart';

/// Registro centrale delle interazioni.
/// L'Agente aggiungerà qui le nuove chiavi (es. "MARINE": marineScenario).
class DiagramRegistry {
  static final Map<String, DiagramScene> _scenarios = {
    "ML_MODEL": mlModelScenario,
    // "MARINE": marineScenario, // Futura espansione
  };

  static DiagramScene? getScenario(String nodeId) => _scenarios[nodeId];

  static bool hasScenario(String nodeId) => _scenarios.containsKey(nodeId);

  // --- MODIFICA (Aggiunta metodo mancante) ---
  /// Registra dinamicamente un nuovo scenario (Usato dall'Agent)
  static void registerScenario(String id, DiagramScene scenario) {
    _scenarios[id] = scenario;
  }

  // Singleton accessor (per compatibilità con il codice dell'Agent che usa .instance)
  static final DiagramRegistry instance = DiagramRegistry._private();
  DiagramRegistry._private();
  // --- FINE MODIFICA ---
}
