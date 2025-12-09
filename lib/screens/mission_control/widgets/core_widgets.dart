import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PlatinumCard extends StatelessWidget {
  final Widget child;
  const PlatinumCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF050B14).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 1)
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 12, color: Colors.cyanAccent),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: Colors.white10)),
      ],
    );
  }
}
