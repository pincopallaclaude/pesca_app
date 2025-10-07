// /lib/widgets/score_chart_dialog.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/forecast_data.dart';
import 'glassmorphism_card.dart';

void showScoreChartDialog(
    BuildContext context, List<Map<String, dynamic>> hourlyScores) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Score Chart Dialog',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) =>
        ScoreChartDialog(hourlyScores: hourlyScores),
    transitionBuilder: (context, anim1, anim2, child) => BackdropFilter(
      filter:
          ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

class ScoreChartDialog extends StatefulWidget {
  final List<Map<String, dynamic>> hourlyScores;
  const ScoreChartDialog({required this.hourlyScores, super.key});

  @override
  State<ScoreChartDialog> createState() => _ScoreChartDialogState();
}

class _ScoreChartDialogState extends State<ScoreChartDialog> {
  static const double _IDEAL_SCORE_THRESHOLD = 4.5;

  int? _selectedIndex;
  late final List<FlSpot> _spots;

  late double _minScore;
  late double _maxScore;

  @override
  void initState() {
    super.initState();
    _spots = widget.hourlyScores.asMap().entries.map((entry) {
      final index = entry.key;
      final score = (entry.value['score'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), score);
    }).toList();

    _updateMinMaxScores();
  }

  void _updateMinMaxScores() {
    if (_spots.isEmpty) {
      _minScore = 0.0;
      _maxScore = 6.0;
      return;
    }
    final scores = _spots.map((spot) => spot.y).toList();
    _minScore = scores.reduce(min);
    _maxScore = scores.reduce(max);
  }

  void _handleTouch(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlLongPressStart || event is FlLongPressMoveUpdate) {
      if (response?.lineBarSpots == null || response!.lineBarSpots!.isEmpty)
        return;
      final spotIndex = response.lineBarSpots!.first.spotIndex;
      if (_selectedIndex != spotIndex) {
        setState(() {
          _selectedIndex = spotIndex;
          HapticFeedback.lightImpact();
        });
      }
    }
  }

  List<TouchedSpotIndicatorData> _getSpotIndicator(
      LineChartBarData barData, List<int> spotIndexes) {
    return spotIndexes
        .map((_) => TouchedSpotIndicatorData(
              FlLine(
                  color: Colors.white.withOpacity(0.5),
                  strokeWidth: 1.5,
                  dashArray: [4, 4]),
              FlDotData(
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                          radius: 8,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.cyanAccent)),
            ))
        .toList();
  }

  LinearGradient _getDynamicGradient() {
    final highColor = Colors.cyan.withOpacity(0.6);
    final lowColor = const Color(0xFF003C48).withOpacity(0.4);
    final bottomColor = Colors.cyan.withOpacity(0.0);

    if (_selectedIndex == null || _selectedIndex! >= _spots.length) {
      return LinearGradient(
          colors: [Colors.cyan.withOpacity(0.4), bottomColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter);
    }
    final score = _spots[_selectedIndex!].y;
    final t = ((score - _minScore) / (_maxScore - _minScore)).clamp(0.0, 1.0);
    final topColor = Color.lerp(lowColor, highColor, t)!;
    return LinearGradient(
        colors: [topColor, bottomColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteracting = _selectedIndex != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: GlassmorphismCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Andamento Potenziale Pesca',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                        enabled: true,
                        touchCallback: _handleTouch,
                        getTouchedSpotIndicator: _getSpotIndicator,
                        longPressDuration: const Duration(milliseconds: 200),
                        touchTooltipData:
                            LineTouchTooltipData(getTooltipItems: (_) => [])),
                    extraLinesData: ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                          y: _IDEAL_SCORE_THRESHOLD,
                          color: Colors.white.withOpacity(0.2),
                          strokeWidth: 1,
                          dashArray: [8, 4])
                    ]),
                    gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: Colors.white10, strokeWidth: 1),
                        getDrawingVerticalLine: (value) => value % 4 == 0
                            ? const FlLine(
                                color: Colors.white10, strokeWidth: 1)
                            : const FlLine(color: Colors.transparent)),
                    titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 4,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  // [CORREZIONE] Nasconde la prima (0) e l'ultima etichetta.
                                  if (index == 0 ||
                                      index >= widget.hourlyScores.length - 1 ||
                                      index % 4 != 0) {
                                    return const SizedBox.shrink();
                                  }
                                  final time = widget.hourlyScores[index]
                                      ['time'] as String?;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                        time != null
                                            ? '${time.split(':')[0]}h'
                                            : '',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10)),
                                  );
                                }))),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (_spots.length - 1).toDouble(),
                    minY: (_minScore - 0.5).floorToDouble(),
                    maxY: (_maxScore + 1).ceilToDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _spots,
                        isCurved: true,
                        gradient: const LinearGradient(
                            colors: [Color(0xFF66CCCC), Colors.cyanAccent]),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        showingIndicators:
                            _selectedIndex != null ? [_selectedIndex!] : [],
                        belowBarData: BarAreaData(
                            show: true, gradient: _getDynamicGradient()),
                      ),
                    ],
                  ),
                ),
              ),

              // [PREMIUM] Implementazione dell'animazione a 2 fasi
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  // Durante lo scorrimento, usiamo una semplice e pulita dissolvenza.
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: isInteracting
                      ? _buildDetailsSection(
                          key: ValueKey(
                              'details_$_selectedIndex'), // Una chiave stabile per il widget interno
                          index: _selectedIndex!,
                          // Passiamo un booleano per l'animazione di entrata "speciale"
                          isFirstBuild:
                              _selectedIndex == (_selectedIndex ?? -1),
                        )
                      : const SizedBox(key: ValueKey('empty')),
                ),
              ),

              TextButton(
                child: const Text('Chiudi',
                    style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [PREMIUM] La firma del metodo è cambiata per accettare 'isFirstBuild'
  Widget _buildDetailsSection(
      {required Key key, required int index, required bool isFirstBuild}) {
    if (index >= widget.hourlyScores.length) {
      return SizedBox(key: key);
    }
    final data = widget.hourlyScores[index];
    final time = data['time'] as String? ?? '--:--';
    final score = (data['score'] as num?)?.toDouble() ?? 0.0;

    final reasonsList = data['reasons'] as List? ?? [];
    final List<ScoreReason> reasons = reasonsList
        .whereType<Map<String, dynamic>>()
        .map((r) => ScoreReason.fromJson(r))
        .toList();

    Widget content = Column(
      key: key, // Usa la chiave qui per l'AnimatedSwitcher esterno
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Ora $time • Punteggio: ${score.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const Divider(color: Colors.white24, height: 24),
        if (reasons.isNotEmpty)
          Column(
              children:
                  reasons.map((r) => _ScoreReasonListItem(reason: r)).toList())
        else
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Nessun dettaglio specifico per quest\'ora.',
                  style: TextStyle(
                      color: Colors.white54, fontStyle: FontStyle.italic))),
      ],
    );

    // [PREMIUM] Logica per l'animazione di entrata speciale
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      // Usiamo TweenAnimationBuilder per animare l'entrata UNA SOLA VOLTA.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            // Scivola leggermente dal basso (es. da 20px in basso a 0)
            offset: Offset(0, 20 * (1 - value)),
            // Appare in dissolvenza
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: content,
      ),
    );
  }
}

class _ScoreReasonListItem extends StatelessWidget {
  final ScoreReason reason;
  const _ScoreReasonListItem({required this.reason});

  IconData _getIconForReason(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'pressure_down':
        return Icons.arrow_downward_rounded;
      case 'pressure_up':
        return Icons.arrow_upward_rounded;
      case 'pressure':
        return Icons.linear_scale_rounded;
      case 'wind':
        return Icons.air;
      case 'moon':
        return Icons.nightlight_round;
      case 'clouds':
        return Icons.cloud_queue_rounded;
      case 'waves':
        return Icons.waves;
      case 'water_temp':
        return Icons.thermostat_rounded;
      case 'currents':
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorFromType(String type) {
    switch (type.toLowerCase()) {
      case 'positive':
        return Colors.greenAccent;
      case 'negative':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(children: [
          Icon(_getIconForReason(reason.icon), color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(reason.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(reason.points,
              style: TextStyle(
                  color: _getColorFromType(reason.type),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]));
  }
}
