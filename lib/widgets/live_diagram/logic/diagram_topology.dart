// /lib/widgets/live_diagram/logic/diagram_topology.dart

import 'dart:ui';

/// Classe singleton per calcolare e condividere le coordinate tra Painter e Widget.
/// Questo garantisce che Linee e Icone siano sempre perfettamente allineate.
class DiagramTopology {
  final Size size;

  // Coordinate Standard (Tree Layout)
  late final Offset stdMlPos;
  late final Offset stdSuperPos;
  late final Offset stdLlmPos;
  late final Offset stdApiPos;
  late final Offset stdSqlitePos;
  late final Offset stdChromaPos;

  late final Offset stdWeatherPos;
  Offset get stdMeteoPos => stdWeatherPos;
  late final Offset stdMarinePos;
  late final Offset stdSpeciesPos;
  late final Offset stdMemoryPos;

  // Coordinate Focus (Diamond/Sky-Scraper Layout)
  late final Offset focusMlPos;
  late final Offset focusWeatherPos;
  late final Offset focusSuperPos;
  late final Offset focusSqlitePos;
  late final Offset focusUserPos;

  // Coordinate Uscita (Explosion)
  late final Offset exitTop;
  late final Offset exitBottom;

  DiagramTopology(this.size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final workerY = h * 0.82;

    // --- STANDARD ---
    stdMlPos = Offset(w * 0.15, h * 0.15);
    stdSuperPos = Offset(centerX, h * 0.15);
    stdLlmPos = Offset(w * 0.85, h * 0.15);
    stdApiPos = Offset(centerX, h * 0.35);
    stdSqlitePos = Offset(w * 0.2, h * 0.5);
    stdChromaPos = Offset(w * 0.8, h * 0.5);

    // Workers centrati in 4 settori
    stdWeatherPos = Offset(w * 0.125, workerY);
    stdMarinePos = Offset(w * 0.375, workerY);
    stdSpeciesPos = Offset(w * 0.625, workerY);
    stdMemoryPos = Offset(w * 0.875, workerY);

    // --- FOCUS (HYPER-LAYOUT) ---
    // ML: Vertice Alto (15%)
    focusMlPos = Offset(centerX, h * 0.15);
    // Satelliti laterali (Spaziatura 120px)
    focusWeatherPos = Offset(centerX - 120, h * 0.42);
    focusSuperPos = Offset(centerX + 120, h * 0.42);
    // SQLite: Vertice Basso (72%)
    focusSqlitePos = Offset(centerX, h * 0.72);
    // User Feedback: Angolo Basso Sinistra (Deep Anchor)
    focusUserPos = Offset(centerX - 110, h * 0.85);

    // --- EXIT ---
    exitTop = Offset(centerX, -150);
    exitBottom = Offset(centerX, h + 150);
  }

  // Helper per interpolazione
  Offset getPos(Offset start, Offset end, double t) {
    return Offset.lerp(start, end, t)!;
  }
}

