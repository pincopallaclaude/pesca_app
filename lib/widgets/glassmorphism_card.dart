// lib/screens/glassmorphism_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  // NUOVI PARAMETRI PER GESTIRE L'ESPANSIONE
  final bool isExpandable;
  final bool isExpanded;
  final VoidCallback? onHeaderTap;

  const GlassmorphismCard({
    required this.child,
    this.title,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20.0),
    // INIZIALIZZIAMO I NUOVI PARAMETRI
    this.isExpandable = false,
    this.isExpanded = false,
    this.onHeaderTap,
    super.key,
  });

// --- NUOVO CODICE DA SOSTITUIRE (SOLO IL METODO build) ---
  @override
  Widget build(BuildContext context) {
    Widget? headerWidget;
    if (title != null) {
// --- NUOVO CODICE DA SOSTITUIRE (PARTE CENTRALE DEL METODO build) ---
      headerWidget = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (isExpandable)
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child:
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          // L'altezza `height` viene rimossa da qui per evitare conflitti.
          // La card si adatterà al suo contenuto.
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHeaderTap,
              child: Padding(
                padding: padding,
                child: title != null
                    ? Column(
                        // COMANDO CHIAVE: La colonna si adatta al suo contenuto.
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerWidget!,
                          const Divider(color: Colors.white24, height: 24),
                          // Il figlio viene ora inserito direttamente. La sua altezza
                          // (controllata da AnimatedContainer) determinerà l'altezza totale.
                          child,
                        ],
                      )
                    : child,
              ),
            ),
          ),
        ),
      ),
    );
// --- FINE NUOVO CODICE ---
// --- RIGA DI CODICE SUCCESSIVA (INVARIATA, COME CONTESTO) ---
  }
}
