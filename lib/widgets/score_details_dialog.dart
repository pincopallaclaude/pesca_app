// /lib/widgets/score_details_dialog.dart

import 'dart:ui';
import 'package:flutter/foundation.dart'; // Import per kDebugMode
import 'package:flutter/material.dart';
import '../models/forecast_data.dart';
import 'glassmorphism_card.dart';

// --- FUNZIONE `showScoreDetailsDialog` AGGIORNATA ---
void showScoreDetailsDialog(BuildContext context, ForecastData forecast) {
  // 1. Identifichiamo l'ora corrente per trovare i dati corretti
  final now = DateTime.now();
  final currentHourString = "${now.hour.toString().padLeft(2, '0')}:00";

  // Inizializziamo le variabili che popoleremo
  List<ScoreReason> reasonsForCurrentHour = [];
  double scoreForCurrentHour = 0.0;
  String timeForCurrentHour =
      currentHourString; // Usiamo l'ora corrente come fallback

  try {
    // 2. Cerchiamo l'oggetto completo nella lista `hourlyScores`
    final hourlyScoreData = forecast.hourlyScores.firstWhere(
      (score) => score['time'] == currentHourString,
    );

    timeForCurrentHour =
        hourlyScoreData['time'] as String? ?? currentHourString;
    // Assicuriamo che il punteggio sia un double
    scoreForCurrentHour = (hourlyScoreData['score'] as num? ?? 0.0).toDouble();

    // 3. Estraiamo e convertiamo la lista `reasons` dall'oggetto trovato
    if (hourlyScoreData['reasons'] != null &&
        hourlyScoreData['reasons'] is List) {
      reasonsForCurrentHour = (hourlyScoreData['reasons'] as List)
          .whereType<Map<String, dynamic>>()
          .map((r) => ScoreReason.fromJson(r))
          .toList();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
          '[ScoreDetailsDialog] Errore nel trovare i dati per l\'ora $currentHourString: $e');
    }
  }

  showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Score Details',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      // Il transitionBuilder originale è semplificato come richiesto.
      // 4. Passiamo tutti i dati necessari (reasons, time, score) al widget del dialogo
      pageBuilder: (context, anim1, anim2) => ScoreDetailsDialog(
            reasons: reasonsForCurrentHour,
            time: timeForCurrentHour,
            score: scoreForCurrentHour,
          ),
      transitionBuilder: (context, anim1, anim2, child) {
        // Modifica: rimozione di SlideTransition e mantenimento solo del blur e fade
        return BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      });
}

// --- WIDGET `ScoreDetailsDialog` AGGIORNATO ---
class ScoreDetailsDialog extends StatelessWidget {
  // Aggiornamento: ora accetta i dati pre-estratti
  final List<ScoreReason> reasons;
  final String time;
  final double score;

  const ScoreDetailsDialog({
    required this.reasons,
    required this.time,
    required this.score,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Aggiornamento: rimosso insetPadding per uniformità
      child: GlassmorphismCard(
        // Aggiornamento: aggiunto padding uniforme come suggerito
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Aggiornamento: allunga il TextButton
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === INTESTAZIONE "PREMIUM" ===
            const Text(
              'Analisi Punteggio',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            // Aggiornamento: usa 'time' e 'score'
            Text(
              'Ora ${time.split(':')[0]}:00 • Punteggio: ${score.toStringAsFixed(1)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),

            // Logica per mostrare i dati o un messaggio di fallback
            if (reasons.isNotEmpty)
              ...List.generate(
                  reasons.length,
                  (index) => AnimatedListItem(
                      index: index,
                      child: _ScoreReasonListItem(reason: reasons[index])))
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('Dettagli non disponibili per l\'ora corrente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
              ),

            const SizedBox(height: 20),
            TextButton(
              child: const Text('Chiudi',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }
}

// --- _ScoreReasonListItem (MANTENUTO DALL'ORIGINALE) ---
class _ScoreReasonListItem extends StatelessWidget {
  final ScoreReason reason;
  const _ScoreReasonListItem({required this.reason, super.key});

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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(children: [
        Icon(_getIconForReason(reason.icon), color: Colors.white70, size: 22),
        const SizedBox(width: 16),
        Expanded(
            child: Text(reason.text,
                style: const TextStyle(color: Colors.white, fontSize: 15))),
        Text(reason.points,
            style: TextStyle(
                color: _getColorFromType(reason.type),
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ]),
    );
  }
}

// --- AnimatedListItem (IMPLEMENTAZIONE DI PLACEHOLDER) ---
// Questo widget è necessario per compilare la logica nel build di ScoreDetailsDialog.
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  const AnimatedListItem({required this.index, required this.child, super.key});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(widget.index * 0.1, 1.0, curve: Curves.easeOut),
    ));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}
