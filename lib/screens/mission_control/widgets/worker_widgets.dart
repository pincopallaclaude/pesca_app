import 'dart:math';
import 'package:flutter/material.dart';
import '../models.dart';

Widget build3DWorkerRow(String name, WorkerStatus worker, Color color, AnimationController controller,
    Map<String, bool> workerExpandedState, Function(String) toggleExpansion, Function(WorkerStatus, String) triggerRestart) {
  
  // Icona Status
  Widget statusIcon;
  if (worker.status == "PROCESSING") {
    statusIcon = Row(
      children: [1, 2, 3].map((i) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final opacity = (sin((controller.value * 2 * pi) + (i * 1.0)) + 1) / 2;
            return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 3,
                height: 3,
                decoration: BoxDecoration(color: color.withValues(alpha: opacity), shape: BoxShape.circle));
          })).toList(),
    );
  } else if (worker.status == "ACTIVE" || worker.status == "ROUTING") {
    statusIcon = RotationTransition(
      turns: controller,
      child: Icon(Icons.incomplete_circle, size: 10, color: color),
    );
  } else if (worker.status == "RESTARTING") {
    statusIcon = AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final opacity = (sin(controller.value * 2 * pi) + 1) / 2;
        return Icon(Icons.flash_on, size: 14, color: Colors.redAccent.withValues(alpha: 0.5 + opacity * 0.5));
      },
    );
  } else {
    statusIcon = Icon(Icons.circle, size: 6, color: Colors.white30);
  }

  // Progress Bar
  Widget progressBarWidget = Tooltip(
    message: worker.status == "PROCESSING" ? "Processing request..." : "Load: \%",
    textStyle: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
    child: Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(0, 1), blurRadius: 0)],
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: worker.load,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.4), color],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: -1)],
          ),
        ),
      ),
    ),
  );

  Widget expandedDetails = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 10),
      const Text("EXECUTION METRICS", style: TextStyle(color: Colors.white54, fontSize: 8)),
      _buildDetailRow("Memory Footprint", "128MB", Colors.white),
      _buildDetailRow("Thread Count", "4", Colors.white),
      _buildDetailRow("Avg. Task Time", "250ms", Colors.white),
      const SizedBox(height: 10),
      const Text("RECENT LOGS", style: TextStyle(color: Colors.white54, fontSize: 8)),
      Text("  [INFO] Task completed", style: TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Courier')),
      const SizedBox(height: 10),
      Center(
        child: SizedBox(
          height: 30,
          child: ElevatedButton.icon(
            onPressed: () => triggerRestart(worker, name),
            icon: const Icon(Icons.autorenew, size: 14),
            label: Text(worker.status == "RESTARTING" ? "RESTARTING..." : "RESTART", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: worker.status == "RESTARTING" ? Colors.redAccent : Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      )
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () => toggleExpansion(name),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 42.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: statusIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Row(
                          children: [
                            Text(worker.status, style: TextStyle(color: color, fontSize: 9, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                            if (worker.status != 'IDLE' && worker.status != 'RESTARTING')
                              Padding(padding: const EdgeInsets.only(left: 4.0), child: Icon(Icons.autorenew, size: 12, color: Colors.white24)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    progressBarWidget,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: (workerExpandedState[name] ?? false) ? 230.0 : 0.0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 0.0),
            child: Opacity(
                opacity: (workerExpandedState[name] ?? false) ? 1.0 : 0.0,
                child: expandedDetails),
          ),
        ),
      ),
    ],
  );
}

Widget _buildDetailRow(String label, String value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        Text(value, style: TextStyle(color: color, fontSize: 9, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
