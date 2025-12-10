// /lib/widgets/live_flow_diagram_nodes.dart

import 'package:flutter/material.dart';

// --- NODE DETAIL OVERLAY (Terminale) ---
class NodeDetailOverlay extends StatelessWidget {
  final String nodeId;
  final VoidCallback onClose;
  const NodeDetailOverlay(
      {super.key, required this.nodeId, required this.onClose});

  Map<String, dynamic> _getNodeData(String id) {
    switch (id) {
      case "SUPER_AGENT":
        return {
          "Status": "ORCHESTRATING",
          "Active Threads": 4,
          "Routing": "PARALLEL"
        };
      case "ML_MODEL":
        return {"Model": "ONNX v2.1", "Inference": "12ms", "Score": "7.8/10"};
      case "LLM":
        return {
          "Provider": "Gemini Flash",
          "Tokens": 450,
          "Status": "CONNECTED"
        };
      case "METEO":
        return {
          "Source": "OpenMeteo",
          "Data": "Wind, Press",
          "Status": "ACTIVE"
        };
      case "MARINE":
        return {"Source": "MarineAPI", "Waves": "2.0m", "Dir": "77° NE"};
      case "SPECIES":
        return {"Target": "Spigola", "Source": "ChromaKB", "Docs": "3 Found"};
      case "MEMORY":
        return {"DB": "SQLite", "Episodes": "452", "Matches": "2 High"};
      case "SQLITE":
        return {"Tables": 4, "Size": "4.2MB", "Query": "0.5ms"};
      case "CHROMA":
        return {"Collection": "fishing_kb", "Vectors": 1240};
      case "API":
        return {"Rate Limit": "OK", "Requests": "45/min", "Latency": "80ms"};
      default:
        return {"Status": "UNKNOWN", "ID": id};
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getNodeData(nodeId);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Opacity(
            opacity: val,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                border: Border.all(color: Colors.greenAccent, width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.2),
                      blurRadius: 20)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(">> NODE: $nodeId",
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold)),
                      GestureDetector(
                          onTap: onClose,
                          child: const Icon(Icons.close,
                              color: Colors.white70, size: 16)),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  ...data.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Courier',
                                    fontSize: 12)),
                            Text(e.value.toString(),
                                style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- INTERACTIVE NODE WRAPPER ---
class InteractiveNode extends StatelessWidget {
  final String id;
  final Widget child;
  final VoidCallback onTap;
  final bool isDimmed;
  const InteractiveNode(
      {super.key,
      required this.id,
      required this.child,
      required this.onTap,
      required this.isDimmed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isDimmed ? 0.05 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: isDimmed ? 0.9 : 1.0,
          child: child,
        ),
      ),
    );
  }
}

// --- VISUAL NODE WIDGETS ---
class AgentNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AnimationController? pulseController;
  final bool isActive;
  final double size;
  const AgentNode(
      {super.key,
      required this.icon,
      required this.label,
      required this.color,
      this.pulseController,
      required this.isActive,
      this.size = 80});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController ?? const AlwaysStoppedAnimation(0),
      builder: (context, _) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.8), width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: color
                            .withOpacity(0.6 * (pulseController?.value ?? 1)),
                        blurRadius: 25,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: size * 0.35),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier'))
          ]),
        );
      },
    );
  }
}

class BaseNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final double border;
  const BaseNode(
      {super.key,
      required this.icon,
      required this.label,
      required this.color,
      required this.size,
      this.border = 1.5});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0F172A).withOpacity(0.8),
          border: Border.all(color: color.withOpacity(0.6), width: border),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)
          ]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier'))
      ]),
    );
  }
}

class InfraNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const InfraNode(
      {super.key,
      required this.icon,
      required this.label,
      required this.color});
  @override
  Widget build(BuildContext context) =>
      BaseNode(icon: icon, label: label, color: color, size: 60);
}

class DatabaseNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const DatabaseNode(
      {super.key,
      required this.icon,
      required this.label,
      required this.color});
  @override
  Widget build(BuildContext context) =>
      BaseNode(icon: icon, label: label, color: color, size: 70, border: 2);
}

class WorkerNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double load;
  const WorkerNode(
      {super.key,
      required this.icon,
      required this.label,
      required this.color,
      required this.load});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: load > 0 ? color : Colors.white10),
            boxShadow: load > 0
                ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)]
                : []),
        child: Stack(alignment: Alignment.center, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold))
          ]),
          if (load > 0)
            Positioned(
                bottom: 6,
                left: 10,
                right: 10,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                        value: load,
                        backgroundColor: Colors.white10,
                        color: color,
                        minHeight: 3))),
        ]),
      ),
    ]);
  }
}
