// /lib/widgets/live_diagram/ui/diagram_ai_dialogs.dart

import 'package:flutter/material.dart';
import '../ai/scenario_request_v2.dart';
import '../ai/models/node_metadata.dart';

class CreateScenarioDialog extends StatefulWidget {
  final Function(ScenarioRequestV2) onSubmit;
  const CreateScenarioDialog({super.key, required this.onSubmit});
  @override
  State<CreateScenarioDialog> createState() => _CreateScenarioDialogState();
}

class _CreateScenarioDialogState extends State<CreateScenarioDialog> {
  final _idController = TextEditingController();
  final _focusController = TextEditingController();
  String? _semanticType = 'real-time';
  QualityPreset _quality = QualityPreset.balanced;
  bool _autoExpand = true;

  @override
  void dispose() {
    _idController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: const Text('Create New Scenario V2',
          style: TextStyle(color: Colors.cyanAccent)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Scenario ID',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'e.g., M2',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: null,
              decoration: const InputDecoration(
                labelText: 'Focus Node',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: ['real-time', 'batch', 'exploratory', 'critical-path']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _semanticType = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<QualityPreset>(
              value: _quality,
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Quality Preset',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: QualityPreset.values
                  .map((q) => DropdownMenuItem(value: q, child: Text(q.name)))
                  .toList(),
              onChanged: (val) => setState(() => _quality = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _focusController.text.isNotEmpty &&
                      GlobalNodeRegistry.has(_focusController.text)
                  ? _focusController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Focus Node',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white),
              items: GlobalNodeRegistry.getAllNodeIds()
                  .toSet()
                  .toList()
                  .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _focusController.text = val ?? ''),
            ),
            const SizedBox(height: 12),
            const Text(' Focus Node must match the node you want to click!',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto-Expand Context',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Include node dependencies automatically',
                  style: TextStyle(color: Colors.white54, fontSize: 10)),
              value: _autoExpand,
              activeColor: Colors.cyanAccent,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _autoExpand = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_focusController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Focus Node is required!'),
                  backgroundColor: Colors.red));
              return;
            }
            final focusNode = _focusController.text.toUpperCase();
            final request = ScenarioRequestV2(
              scenarioId: _idController.text.toUpperCase(),
              semanticType: _semanticType,
              qualityPreset: _quality,
              focusNode: focusNode,
              autoExpandContext: _autoExpand,
              dataFlow: _autoExpand
                  ? {focusNode: []}
                  : {
                      'API': [focusNode],
                      focusNode: ['SUPER_AGENT'],
                      'SUPER_AGENT': ['SQLITE'],
                    },
            );
            widget.onSubmit(request);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class SelectScenarioDialog extends StatelessWidget {
  final List<String> scenarios;
  final String title;
  final Function(String) onSelected;
  const SelectScenarioDialog(
      {super.key,
      required this.scenarios,
      required this.title,
      required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: Text(title, style: const TextStyle(color: Colors.cyanAccent)),
      content: SizedBox(
        width: 300,
        child: scenarios.isEmpty
            ? const Center(
                child: Text('No scenarios available',
                    style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: scenarios.length,
                itemBuilder: (context, index) {
                  final id = scenarios[index];
                  return ListTile(
                    leading:
                        const Icon(Icons.timeline, color: Colors.cyanAccent),
                    title:
                        Text(id, style: const TextStyle(color: Colors.white)),
                    onTap: () => onSelected(id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'))
      ],
    );
  }
}
