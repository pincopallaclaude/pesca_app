// /lib/screens/mission_control/mission_control_view_model.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';

class MissionControlViewModel extends ChangeNotifier {
  Timer? _timer;

  // Data State
  List<double> latencyHistory = List.filled(50, 20.0, growable: true);
  double threatScore = 5.0;
  double cpuLoad = 12.0;
  double predictedLatency = 45.0;
  double threatBaseline = 2.5;
  double latencyConfidence = 5.0;
  double cpuTimeToSaturation = 4.0;
  double memTimeToSaturation = 8.0;
  double currentThroughputTx = 12.5;
  double currentThroughputRx = 8.9;
  double packetLossRate = 0.1;
  double totalDataTransferredGB = 45.0;
  double latencyBaselineAvg = 20.0;
  Duration cronCountdown = const Duration(hours: 3, minutes: 0, seconds: 0);

  // Infrastructure State
  double sqliteDiskIO = 0.5;
  double chromaHitRate = 0.95;
  bool sqliteSyncing = false;
  bool chromaFlushing = false;

  Map<String, bool> workerExpandedState = {};

  List<LogEntry> logs = [
    LogEntry("09:00:01", "INIT", "System boot sequence initiated"),
    LogEntry("09:00:02", "INFO", "ChromaDB connection established"),
    LogEntry("09:00:05", "INFO", "SuperAgent routing logic loaded"),
  ];

  final Map<String, WorkerStatus> workers = {
    'SUPER_AGENT_CORE': WorkerStatus('ACTIVE', 0.15, Colors.white),
    'METEO_ANALYST': WorkerStatus('IDLE', 0.05, Colors.blue),
    'MARINE_SPECIALIST': WorkerStatus('PROCESSING', 0.85, Colors.cyan),
    'SPECIES_ADVISOR': WorkerStatus('READY', 0.2, Colors.teal),
    'MEMORY_RETRIEVER': WorkerStatus('INDEXING', 0.45, Colors.orange),
  };

  MissionControlViewModel() {
    for (var key in workers.keys) {
      workerExpandedState[key] = false;
    }
  }

  void init() {
    _timer = Timer.periodic(const Duration(milliseconds: 800), _updateMetrics);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateMetrics(Timer timer) {
    // 1. Latency Plasma
    latencyHistory.removeAt(0);
    double noise = (Random().nextDouble() - 0.5) * 10;
    double trend = sin(timer.tick / 10) * 15;
    latencyHistory.add((20.0 + trend + noise).clamp(5.0, 100.0));

    // 2. Threat & Resources
    threatScore =
        (threatScore + (Random().nextDouble() - 0.5)).clamp(0.0, 100.0);
    cpuLoad = (cpuLoad + (Random().nextDouble() - 0.5) * 5).clamp(10.0, 90.0);
    predictedLatency = latencyHistory.last * 1.2;

    // 3. Network Metrics
    currentThroughputTx =
        (currentThroughputTx + (Random().nextDouble() - 0.5)).clamp(10.0, 20.0);
    currentThroughputRx =
        (currentThroughputRx + (Random().nextDouble() - 0.5)).clamp(5.0, 15.0);

    // 4. Cron
    if (cronCountdown.inSeconds > 0) {
      cronCountdown -= const Duration(milliseconds: 800);
    } else {
      cronCountdown = const Duration(hours: 6);
    }

    // 5. Random Logs
    if (Random().nextDouble() > 0.85) _addRandomLog();

    // 6. Worker Simulation
    if (Random().nextDouble() > 0.6) {
      final workerKey =
          workers.keys.elementAt(Random().nextInt(workers.length));
      workers[workerKey]!.load =
          (0.1 + Random().nextDouble() * 0.8).clamp(0.0, 1.0);
      workers[workerKey]!.status = workers[workerKey]!.load > 0.8
          ? "PROCESSING"
          : (workers[workerKey]!.load > 0.5 ? "ACTIVE" : "IDLE");
    }
    notifyListeners();
  }

  void _addRandomLog({String level = "INFO", String? message}) {
    final now = DateTime.now();
    final ts =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    if (message != null) {
      logs.insert(0, LogEntry(ts, level, message));
    } else {
      final actions = ["Syncing", "Vectorizing", "Fetching", "Routing"];
      final targets = [
        "MeteoData",
        "UserFeedback",
        "MarineAPI",
        "KnowledgeBase"
      ];
      logs.insert(
          0,
          LogEntry(ts, "INFO",
              "${actions[Random().nextInt(actions.length)]} ${targets[Random().nextInt(targets.length)]} (${Random().nextInt(100)}ms)"));
    }
    if (logs.length > 20) logs.removeLast();
  }

  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void startSqliteSync() {
    if (sqliteSyncing) return;
    sqliteSyncing = true;
    sqliteDiskIO = 1.0;
    _addRandomLog(level: "TASK", message: "SQLITE: Force Sync Initiated");
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      sqliteSyncing = false;
      _addRandomLog(level: "TASK", message: "SQLITE: Sync Complete");
      notifyListeners();
    });
  }

  void startChromaFlush() {
    if (chromaFlushing) return;
    chromaFlushing = true;
    _addRandomLog(level: "TASK", message: "CHROMA: Flush Initiated");
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1500), () {
      chromaFlushing = false;
      chromaHitRate = 0.99;
      _addRandomLog(level: "TASK", message: "CHROMA: Flush Complete");
      notifyListeners();
    });
  }

  void toggleWorkerExpansion(String name) {
    workerExpandedState[name] = !(workerExpandedState[name] ?? false);
    notifyListeners();
  }

  void triggerWorkerRestart(WorkerStatus worker, String name) {
    _addRandomLog(level: "TASK", message: "$name: Restart initiated.");
    worker.status = "RESTARTING";
    worker.load = 0.0;
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      worker.status = "ACTIVE";
      worker.load = 0.1;
      _addRandomLog(level: "TASK", message: "$name: Restart complete.");
      notifyListeners();
    });
  }

  void triggerProactiveCron() {
    cronCountdown = const Duration(hours: 6);
    _addRandomLog(level: "CRON", message: "PROACTIVE triggered manually.");
    notifyListeners();
  }
}
