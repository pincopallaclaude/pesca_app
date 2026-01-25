// /lib/widgets/live_diagram/ui/diagram_ai_button.dart

import 'package:flutter/material.dart';
import 'diagram_ai_console.dart';

class DiagramAIButton extends StatelessWidget {
  final VoidCallback? onScenarioCreated;
  const DiagramAIButton({super.key, this.onScenarioCreated});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: SizedBox(
              width: 800,
              height: 600,
              child: DiagramAIConsole(onScenarioCreated: onScenarioCreated),
            ),
          ),
        );
      },
      icon: const Icon(Icons.smart_toy),
      label: const Text('AI CONSOLE'),
      backgroundColor: Colors.cyanAccent,
      foregroundColor: Colors.black,
    );
  }
}
