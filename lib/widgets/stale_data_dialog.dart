// lib/widgets/stale_data_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'glassmorphism_card.dart';

/// Mostra un dialogo che chiede all'utente se vuole usare i dati obsoleti.
/// Restituisce `true` se l'utente accetta, `false` altrimenti.
Future<bool?> showStaleDataDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Stale Data Dialog',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) => const StaleDataDialog(),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

class StaleDataDialog extends StatelessWidget {
  const StaleDataDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassmorphismCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.cyan[200], size: 48),
              const SizedBox(height: 16),
              const Text(
                'Impossibile Aggiornare',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Non è stato possibile recuperare nuove previsioni. Vuoi visualizzare gli ultimi dati disponibili?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false), // Rifiuta
                    child: const Text('No, grazie', style: TextStyle(color: Colors.white70)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true), // Accetta
                    child: const Text('Visualizza', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}