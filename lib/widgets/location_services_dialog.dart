// lib/widgets/location_services_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'glassmorphism_card.dart';

/// Funzione helper per mostrare il dialogo modale personalizzato.
/// Utilizza la stessa logica di animazione degli altri dialoghi dell'app.
void showLocationServicesDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Location Services Dialog',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) => const LocationServicesDialog(),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}

class LocationServicesDialog extends StatelessWidget {
  const LocationServicesDialog({super.key});

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
              Icon(Icons.location_off_outlined, color: Colors.cyan[200], size: 48),
              const SizedBox(height: 16),
              const Text(
                'Localizzazione Disattivata',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Per rilevare la tua posizione, Pesca Meteo ha bisogno che i servizi di localizzazione siano attivi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              // Pulsante di azione primaria
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  // Reindirizza l'utente alle impostazioni di localizzazione
                  AppSettings.openAppSettings(type: AppSettingsType.location);
                  Navigator.of(context).pop();
                },
                child: const Text('Vai alle Impostazioni', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              // Pulsante di azione secondaria
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}