import 'package:flutter/material.dart';

class PremiumDrawerHeader extends StatelessWidget {
  final AnimationController scanlineController;

  const PremiumDrawerHeader({super.key, required this.scanlineController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.15))),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.cyanAccent.withValues(alpha: 0.05), Colors.transparent],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.15), blurRadius: 30)],
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.hub, size: 42, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 14),
                const Text("NEPTUNE OS", style: TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
                  ),
                  child: const Text("NEURAL LINK ACTIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 8, letterSpacing: 1.5, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: scanlineController,
            builder: (context, child) {
              return Positioned(
                top: scanlineController.value * 190,
                left: 0, right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.cyanAccent.withValues(alpha: 0.6), Colors.transparent],
                    ),
                    boxShadow: [BoxShadow(color: Colors.cyanAccent, blurRadius: 4)],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
