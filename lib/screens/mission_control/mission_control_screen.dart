// /lib/screens/mission_control/mission_control_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Imports
import 'package:pesca_app/widgets/live_flow_diagram.dart';
import 'mission_control_view_model.dart';
import 'painters.dart';
import 'widgets/core_widgets.dart';
import 'widgets/diagnostic_widgets.dart';
import 'widgets/infrastructure_widgets.dart';
import 'widgets/network_widgets.dart';
import 'widgets/worker_widgets.dart';
import 'widgets/log_widgets.dart';

class MissionControlScreen extends StatefulWidget {
  const MissionControlScreen({super.key});

  @override
  State<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends State<MissionControlScreen>
    with TickerProviderStateMixin {
  // Logic Controller
  final MissionControlViewModel _vm = MissionControlViewModel();

  // UI Animation Controllers
  late AnimationController _flowController;
  late AnimationController _pulseController;
  Offset _parallaxOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Inizializza Logica
    _vm.init();

    // Inizializza Animazioni UI
    _flowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _vm.dispose();
    _flowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _parallaxOffset += details.delta * 0.5;
            _parallaxOffset = Offset(_parallaxOffset.dx.clamp(-30.0, 30.0),
                _parallaxOffset.dy.clamp(-30.0, 30.0));
          });
        },
        onPanEnd: (_) => setState(() => _parallaxOffset = Offset.zero),
        child: Stack(
          children: [
            // Background Grid Painter
            Positioned.fill(
              child: Transform.translate(
                offset: _parallaxOffset * 0.2,
                child: CustomPaint(painter: GridPainter()),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    // ListenableBuilder ascolta il ViewModel e ricostruisce la UI quando i dati cambiano
                    child: ListenableBuilder(
                        listenable: _vm,
                        builder: (context, child) {
                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              const SectionLabel(
                                  label: "LIVE PROCESS TOPOLOGY"),
                              const SizedBox(height: 16),
                              LiveFlowDiagram(
                                flowController: _flowController,
                                pulseController: _pulseController,
                                workers: _vm.workers,
                                parallaxOffset: _parallaxOffset,
                              ),
                              const SizedBox(height: 30),
                              const SectionLabel(label: "NEURAL WORKER SWARM"),
                              const SizedBox(height: 12),
                              PlatinumCard(
                                child: Column(
                                  children: _vm.workers.entries.map((entry) {
                                    return Column(children: [
                                      build3DWorkerRow(
                                          entry.key,
                                          entry.value,
                                          entry.value.color,
                                          _pulseController,
                                          _vm.workerExpandedState,
                                          _vm.toggleWorkerExpansion,
                                          _vm.triggerWorkerRestart),
                                      if (entry.key != _vm.workers.keys.last)
                                        const SizedBox(height: 2)
                                    ]);
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 30),
                              const SectionLabel(
                                  label: "PREDICTIVE DIAGNOSTICS"),
                              const SizedBox(height: 12),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                        child: PlatinumCard(
                                            child: buildThreatGaugeContent(
                                                _vm.threatScore,
                                                _vm.threatBaseline,
                                                _vm.latencyHistory))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: PlatinumCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          buildResourceRowContent(
                                              "CPU LOAD",
                                              _vm.cpuLoad,
                                              Colors.cyanAccent,
                                              _vm.cpuTimeToSaturation,
                                              _vm.memTimeToSaturation,
                                              context),
                                          const SizedBox(height: 15),
                                          buildResourceRowContent(
                                              "MEM ALLOC",
                                              45.0 + (_vm.cpuLoad / 4),
                                              Colors.purpleAccent,
                                              _vm.cpuTimeToSaturation,
                                              _vm.memTimeToSaturation,
                                              context),
                                          const SizedBox(height: 15),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("PREDICTED LATENCY (90% CI)",
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.5),
                                                      fontSize: 9)),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.baseline,
                                                textBaseline:
                                                    TextBaseline.alphabetic,
                                                children: [
                                                  Text(
                                                      "${_vm.predictedLatency.toInt()}ms",
                                                      style: const TextStyle(
                                                          color: Colors
                                                              .orangeAccent,
                                                          fontSize: 18,
                                                          fontFamily: 'Courier',
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      "± ${_vm.latencyConfidence.toInt()}ms",
                                                      style: TextStyle(
                                                          color: Colors
                                                              .orangeAccent
                                                              .withValues(
                                                                  alpha: 0.7),
                                                          fontSize: 12,
                                                          fontFamily:
                                                              'Courier')),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: const [
                                              Icon(Icons.check_circle,
                                                  size: 8, color: Colors.green),
                                              SizedBox(width: 4),
                                              Text("MODEL DRIFT: OK",
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              PlatinumCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("NETWORK LATENCY",
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                              "${_vm.latencyHistory.last.toInt()}ms",
                                              style: const TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontSize: 14,
                                                  fontFamily: 'Courier',
                                                  fontWeight: FontWeight.bold)),
                                        ]),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                        height: 60,
                                        width: double.infinity,
                                        child: CustomPaint(
                                            painter: PlasmaGraphPainter(
                                                data: _vm.latencyHistory,
                                                latencyBaseline:
                                                    _vm.latencyBaselineAvg))),
                                    const SizedBox(height: 15),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          buildNetworkIODetail(
                                              "PKT LOSS",
                                              "${_vm.packetLossRate.toStringAsFixed(1)}%",
                                              Colors.redAccent),
                                          buildNetworkIODetail(
                                              "DATA",
                                              "${_vm.totalDataTransferredGB.toStringAsFixed(1)} GB",
                                              Colors.white),
                                          buildThroughput(
                                              _vm.currentThroughputTx,
                                              _vm.currentThroughputRx),
                                        ]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              const SectionLabel(label: "INFRASTRUCTURE LAYER"),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: buildInfraStatus(
                                          "SQLITE",
                                          "452",
                                          "Episodes",
                                          "DISK IO",
                                          _vm.sqliteDiskIO,
                                          _vm.startSqliteSync,
                                          _vm.sqliteSyncing,
                                          Colors.blue,
                                          Icons.storage_outlined,
                                          _pulseController)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: buildInfraStatus(
                                          "CHROMA",
                                          "1.2k",
                                          "Vectors",
                                          "HIT RATE",
                                          _vm.chromaHitRate,
                                          _vm.startChromaFlush,
                                          _vm.chromaFlushing,
                                          Colors.purple,
                                          Icons.scatter_plot,
                                          _pulseController)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildCronJobCard(
                                      title: "PROACTIVE",
                                      icon: Icons.schedule_outlined,
                                      color: Colors.greenAccent,
                                      statusLabel:
                                          _vm.formatDuration(_vm.cronCountdown),
                                      detailLabel: "Next",
                                      onTrigger: _vm.triggerProactiveCron,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: buildCronJobCard(
                                      title: "CLEANUP",
                                      icon: Icons.cleaning_services_outlined,
                                      color: Colors.orangeAccent,
                                      statusLabel: "IDLE",
                                      detailLabel: "Last Run: 01:00 UTC",
                                      onTrigger: null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              const SectionLabel(label: "SYSTEM LOGS"),
                              const SizedBox(height: 12),
                              buildTerminalLogs(_vm.logs),
                            ],
                          );
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
        color: Color(0xFF050B14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
              onPressed: () => Navigator.pop(context)),
          const Text("MISSION CONTROL",
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 3)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent),
                borderRadius: BorderRadius.circular(4),
                color: Colors.greenAccent.withValues(alpha: 0.1)),
            child: const Text("LIVE",
                style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
