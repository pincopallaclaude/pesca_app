// /lib/widgets/live_diagram/ai/models/node_metadata.dart

import 'package:flutter/material.dart';

/// Metadati globali per ogni tipo di nodo nell'architettura.
/// Usati dal Semantic Engine per auto-risoluzione e inferenza intelligente.
class NodeMetadata {
  final String id;
  final Color defaultColor;
  final double defaultSize; // Dimensione visuale (in pixel/unità rendering)

  /// NUOVO: Raggio di collisione per il calcolo del layout (0.0 - 1.0).
  /// Rappresenta l'ingombro fisico del nodo rispetto alle dimensioni dello schermo.
  final double collisionRadius;

  final String
      category; // 'orchestrator', 'processor', 'storage', 'api', 'sensor', 'interaction'
  final Offset? defaultPosition;
  final List<String> typicalConnections;
  final Map<String, dynamic> properties;

  const NodeMetadata({
    required this.id,
    required this.defaultColor,
    required this.defaultSize,
    required this.collisionRadius,
    required this.category,
    this.defaultPosition,
    this.typicalConnections = const [],
    this.properties = const {},
  });

  /// Crea copia con override di campi
  NodeMetadata copyWith({
    String? id,
    Color? defaultColor,
    double? defaultSize,
    double? collisionRadius,
    String? category,
    Offset? defaultPosition,
    List<String>? typicalConnections,
    Map<String, dynamic>? properties,
  }) {
    return NodeMetadata(
      id: id ?? this.id,
      defaultColor: defaultColor ?? this.defaultColor,
      defaultSize: defaultSize ?? this.defaultSize,
      collisionRadius: collisionRadius ?? this.collisionRadius,
      category: category ?? this.category,
      defaultPosition: defaultPosition ?? this.defaultPosition,
      typicalConnections: typicalConnections ?? this.typicalConnections,
      properties: properties ?? this.properties,
    );
  }
}

/// Registry globale pre-popolato con nodi standard dell'architettura.
class GlobalNodeRegistry {
  static final Map<String, NodeMetadata> _metadata = {
    'SUPER_AGENT': const NodeMetadata(
      id: 'SUPER_AGENT',
      defaultColor: Colors.white,
      defaultSize: 100.0,
      collisionRadius: 0.18,
      category: 'orchestrator',
      // POSIZIONE: Lato Destro
      defaultPosition: Offset(0.92, 0.65),
      typicalConnections: ['ML_MODEL', 'SQLITE', 'CHROMA', 'MEMORY'],
      properties: {'role': 'central_coordinator', 'priority': 10},
    ),
    'ML_MODEL': const NodeMetadata(
      id: 'ML_MODEL',
      defaultColor: Colors.purpleAccent,
      defaultSize: 90.0,
      collisionRadius: 0.15,
      category: 'processor',
      // POSIZIONE: Centrato in Alto (Top Center)
      defaultPosition: Offset(0.50, 0.10),
      typicalConnections: ['SUPER_AGENT', 'SQLITE'],
      properties: {'role': 'prediction', 'priority': 9},
    ),
    'WEATHER': const NodeMetadata(
      id: 'WEATHER',
      defaultColor: Colors.lightBlue,
      defaultSize: 85.0,
      collisionRadius: 0.12,
      category: 'sensor',
      // POSIZIONE: Lato Sinistro (Left Wing)
      defaultPosition: Offset(0.07, 0.35),
      typicalConnections: ['API', 'SUPER_AGENT'],
      properties: {'role': 'weather_station', 'priority': 7},
    ),
    'MARINE': const NodeMetadata(
      id: 'MARINE',
      defaultColor: Colors.blueAccent,
      defaultSize: 85.0,
      collisionRadius: 0.12,
      category: 'sensor',
      defaultPosition: Offset(0.375, 0.82),
      typicalConnections: ['API', 'SUPER_AGENT'],
      properties: {'role': 'marine_sensor', 'priority': 7},
    ),
    'SPECIES': const NodeMetadata(
      id: 'SPECIES',
      defaultColor: Colors.greenAccent,
      defaultSize: 85.0,
      collisionRadius: 0.12,
      category: 'sensor',
      defaultPosition: Offset(0.625, 0.82),
      typicalConnections: ['CHROMA', 'ML_MODEL'],
      properties: {'role': 'bio_monitor', 'priority': 7},
    ),
    'API': const NodeMetadata(
      id: 'API',
      defaultColor: Colors.orangeAccent,
      defaultSize: 80.0,
      collisionRadius: 0.10,
      category: 'api',
      defaultPosition: Offset(0.50, 0.35),
      typicalConnections: ['WEATHER', 'MARINE'],
      properties: {'role': 'external_interface', 'priority': 6},
    ),
    'SQLITE': const NodeMetadata(
      id: 'SQLITE',
      defaultColor: Colors.cyanAccent,
      defaultSize: 85.0,
      collisionRadius: 0.15,
      category: 'storage',
      // POSIZIONE: Centrato in Basso (sotto ML_MODEL)
      defaultPosition: Offset(0.50, 0.80),
      typicalConnections: ['SUPER_AGENT', 'ML_MODEL', 'MEMORY'],
      properties: {'role': 'relational_db', 'priority': 8},
    ),
    'CHROMA': const NodeMetadata(
      id: 'CHROMA',
      defaultColor: Colors.pinkAccent,
      defaultSize: 80.0,
      collisionRadius: 0.12,
      category: 'storage',
      defaultPosition: Offset(0.80, 0.50),
      typicalConnections: ['SPECIES', 'MEMORY'],
      properties: {'role': 'vector_db', 'priority': 8},
    ),
    'MEMORY': const NodeMetadata(
      id: 'MEMORY',
      defaultColor: Colors.amberAccent,
      defaultSize: 80.0,
      collisionRadius: 0.10,
      category: 'processor',
      defaultPosition: Offset(0.875, 0.82),
      typicalConnections: ['CHROMA', 'SQLITE', 'SUPER_AGENT'],
      properties: {'role': 'context_manager', 'priority': 8},
    ),
    'USER_FEEDBACK': const NodeMetadata(
      id: 'USER_FEEDBACK',
      defaultColor: Colors.pinkAccent,
      defaultSize: 60.0,
      collisionRadius: 0.10,
      category: 'interaction',
      // POSIZIONE: Lato Sinistro, in Basso (Bottom Left)
      defaultPosition: Offset(0.10, 0.95),
      typicalConnections: ['SUPER_AGENT'],
      properties: {'role': 'user_input', 'priority': 5},
    ),
  };

  /// Recupera metadata di un nodo specifico
  static NodeMetadata? get(String nodeId) => _metadata[nodeId];

  /// Verifica esistenza di un nodo nel registro
  static bool has(String nodeId) => _metadata.containsKey(nodeId);

  /// Registra un nuovo nodo o aggiorna uno esistente
  static void register(NodeMetadata metadata) {
    _metadata[metadata.id] = metadata;
  }

  /// Recupera tutti i nodi appartenenti a una categoria specifica
  static List<NodeMetadata> getByCategory(String category) {
    return _metadata.values.where((m) => m.category == category).toList();
  }

  /// Restituisce la lista di tutti gli ID registrati
  static List<String> getAllNodeIds() => _metadata.keys.toList()..sort();

  /// Ottiene il set di tutte le categorie presenti
  static Set<String> getAllCategories() {
    return _metadata.values.map((m) => m.category).toSet();
  }

  /// Inferisce le connessioni suggerite basandosi sull'architettura nota
  static List<String> inferConnections(String nodeId) {
    final metadata = _metadata[nodeId];
    return metadata?.typicalConnections ?? [];
  }

  /// Pulisce il registry (usato principalmente nei test)
  static void resetForTesting() {
    _metadata.clear();
  }
}
