import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/forecast_data.dart'; // Per ScoreReason
import 'glassmorphism_card.dart';

// Funzione helper per mostrare il dialog
void showScoreDetailsDialog(BuildContext context, List<ScoreReason> reasons) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Score Details',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) => ScoreDetailsDialog(reasons: reasons),
    transitionBuilder: (context, anim1, anim2, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

class ScoreDetailsDialog extends StatelessWidget {
  final List<ScoreReason> reasons;

  const ScoreDetailsDialog({required this.reasons, super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassmorphismCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Analisi Punteggio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              ...List.generate(reasons.length, (index) => AnimatedListItem(index: index, child: _ScoreReasonListItem(reason: reasons[index]))),
              const SizedBox(height: 10),
              TextButton(
                child: const Text('Chiudi', style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreReasonListItem extends StatelessWidget {
  final ScoreReason reason;

  const _ScoreReasonListItem({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(_getIconForReason(reason.icon), color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(reason.text, style: const TextStyle(color: Colors.white))),
          Text(
            reason.points,
            style: TextStyle(
              color: reason.type == 'positive'
                  ? Colors.greenAccent
                  : (reason.type == 'negative' ? Colors.redAccent : Colors.white70),
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  IconData _getIconForReason(String iconName) {
    switch (iconName) {
      case 'pressure_down':
        return Icons.arrow_downward_rounded;
      case 'pressure_up':
        return Icons.arrow_upward_rounded;
      case 'wind':
        return Icons.air;
      case 'moon':
        return Icons.nightlight_round;
      case 'clouds':
        return Icons.cloud_queue;
      case 'waves':
        return Icons.waves;
      case 'water_temp':
        return Icons.thermostat;
      case 'currents':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.info_outline;
    }
  }
}

class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({required this.index, required this.child, super.key});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    final delay = widget.index * 60; // Leggero ritardo per effetto cascata
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Interval(delay / 1000, 1.0, curve: Curves.easeOut)));
    _position = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Interval(delay / 1000, 1.0, curve: Curves.easeOut)));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _position, child: widget.child));
}