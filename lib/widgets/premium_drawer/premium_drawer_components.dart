// /lib/widgets/premium_drawer_components.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pesca_app/screens/mission_control/mission_control_screen.dart';

// --- MODELLO DATI ---
class DrawerDataModel {
  String lat = "40.835";
  String lon = "14.220";
  String mem = "40%";

  void updateData() {
    lat = "40.8${10 + math.Random().nextInt(90)}";
    lon = "14.2${05 + math.Random().nextInt(90)}";
    mem = "${40 + math.Random().nextInt(5)}%";
  }
}

// --- CONFIGURAZIONE MENU ITEMS ---
class DrawerMenuItems {
  static final List<Map<String, dynamic>> items = [
    {
      'icon': Icons.monitor_heart,
      'title': "Mission Control",
      'subtitle': "System Status & Logs",
      'color': Colors.red.shade400,
      'screen': const MissionControlScreen()
    },
    {
      'icon': Icons.history,
      'title': "Forecast History",
      'subtitle': "Previous Sessions",
      'color': Colors.blue.shade400,
      'screen': null
    },
    {
      'icon': Icons.map_outlined,
      'title': "Tactical Map",
      'subtitle': "Spots & Zones",
      'color': Colors.cyan.shade400,
      'screen': null
    },
    {
      'icon': Icons.settings_input_component,
      'title': "Neural Config",
      'subtitle': "Agent Parameters",
      'color': Colors.purple.shade400,
      'screen': null
    },
  ];
}

// Estensione per gestire l'opacità
extension ColorAlpha on Color {
  Color withValues({double alpha = 1.0}) {
    return this.withOpacity(alpha.clamp(0.0, 1.0));
  }
}
