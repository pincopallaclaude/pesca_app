import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pesca_app/widgets/live_diagram/ai/diagram_ai_agent.dart';
import '../logic/diagram_registry_enhanced.dart';
import 'diagram_ai_dialogs.dart';

class DiagramAIConsole extends StatefulWidget {
  final VoidCallback? onScenarioCreated;
  const DiagramAIConsole({super.key, this.onScenarioCreated});
  @override
  State<DiagramAIConsole> createState() => _DiagramAIConsoleState();
}

class _DiagramAIConsoleState extends State<DiagramAIConsole> {
  final _agent = DiagramAIAgent();
  String _output = 'AI Agent Console V2.0 Ready\nSemantic-Aware  Perception-Optimized\n';
  final _scrollController = ScrollController();

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  void _addOutput(String text) {
    if (!mounted) return;
    setState(() { _output += '\n$text'; });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _validateAllScenarios() {
    _addOutput('\n>>> VALIDATING ALL SCENARIOS...');
    final results = DiagramRegistryEnhanced.validateAll();
    int v = 0, i = 0, w = 0;
    results.forEach((id, r) { if (r.isValid) { v++; if (r.warnings.isNotEmpty) w++; } else { i++; } });
    _addOutput(' Valid: $v |  Invalid: $i |  Warnings: $w');
  }

  void _createNewScenario() {
    showDialog(context: context, builder: (context) => CreateScenarioDialog(
      onSubmit: (request) {
        _addOutput('\n>>> CREATING SCENARIO: ${request.scenarioId}');
        final nodeKey = request.focusNode?.toUpperCase() ?? request.scenarioId;
        final success = DiagramRegistryEnhanced.createAndRegisterV2WithKey(request, nodeKey, viewportSize: const Size(800, 600));
        if (success) {
          _addOutput(' Scenario created successfully!\n Registered with key: $nodeKey');
          final scene = DiagramRegistryEnhanced.getScenario(nodeKey);
          if (scene != null) {
            final val = _agent.validateScenario(scene);
            _addOutput('    Status: ${val.isValid ? "VALID" : "INVALID"}\n    Nodes: ${scene.nodePositions.length}');
          }
          widget.onScenarioCreated?.call();
          Future.delayed(const Duration(milliseconds: 500), () { if (mounted) Navigator.of(context).pop(); });
        } else { _addOutput(' Failed to create scenario'); }
      },
    ));
  }

  void _optimizeScenario() {
    final s = DiagramRegistryEnhanced.listScenarios();
    showDialog(context: context, builder: (context) => SelectScenarioDialog(
      scenarios: s, title: 'Select Scenario to Optimize',
      onSelected: (id) {
        _addOutput('\n>>> OPTIMIZING SCENARIO: $id');
        if (DiagramRegistryEnhanced.optimizeScenario(id)) {
          _addOutput(' Optimization complete!');
          widget.onScenarioCreated?.call();
        } else { _addOutput(' Optimization failed'); }
        Navigator.of(context).pop();
      },
    ));
  }

  void _exportScenario() {
    final s = DiagramRegistryEnhanced.listScenarios();
    showDialog(context: context, builder: (context) => SelectScenarioDialog(
      scenarios: s, title: 'Select Scenario to Export',
      onSelected: (id) {
        final code = DiagramRegistryEnhanced.exportScenarioCode(id);
        Clipboard.setData(ClipboardData(text: code));
        _addOutput('\n>>> EXPORTING SCENARIO: $id\n Code copied to clipboard!');
        Navigator.of(context).pop();
      },
    ));
  }

  void _showStatistics() => _addOutput('\n${DiagramRegistryEnhanced.getStatistics()}');

  void _showScenarioReport() {
    final s = DiagramRegistryEnhanced.listScenarios();
    showDialog(context: context, builder: (context) => SelectScenarioDialog(
      scenarios: s, title: 'Select Scenario for Report',
      onSelected: (id) { _addOutput('\n${DiagramRegistryEnhanced.getScenarioReport(id)}'); Navigator.of(context).pop(); },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A).withOpacity(0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTerminal(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
    child: Row(children: [
      const Icon(Icons.smart_toy, color: Colors.cyanAccent, size: 28),
      const SizedBox(width: 12),
      const Expanded(child: Text('AI CONSOLE', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier'))),
      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.of(context).pop()),
    ]),
  );

  Widget _buildTerminal() => Expanded(
    child: Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withOpacity(0.3))),
      child: SingleChildScrollView(controller: _scrollController, child: Text(_output, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'Courier', height: 1.4))),
    ),
  );

  Widget _buildActions() => Padding(
    padding: const EdgeInsets.all(16),
    child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
      _btn('Validate All', Icons.check_circle_outline, Colors.greenAccent, _validateAllScenarios),
      _btn('Create New', Icons.add_circle_outline, Colors.cyanAccent, _createNewScenario),
      _btn('Optimize', Icons.tune, Colors.orangeAccent, _optimizeScenario),
      _btn('Export Code', Icons.code, Colors.purpleAccent, _exportScenario),
      _btn('Statistics', Icons.bar_chart, Colors.blueAccent, _showStatistics),
      _btn('Report', Icons.description, Colors.pinkAccent, _showScenarioReport),
    ]),
  );

  Widget _btn(String l, IconData i, Color c, VoidCallback p) => ElevatedButton.icon(
    onPressed: p, icon: Icon(i, size: 18), label: Text(l),
    style: ElevatedButton.styleFrom(foregroundColor: c, backgroundColor: c.withOpacity(0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: c.withOpacity(0.5))),
  );
}
