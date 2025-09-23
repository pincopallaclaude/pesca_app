import 'package:flutter/material.dart';

class FishingScoreIndicator extends StatelessWidget {
  final double score;

  const FishingScoreIndicator({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    int fullFish = score.floor();
    double lastFishOpacity = score - fullFish;

    List<Widget> fishIcons = [];
    for (int i = 0; i < 5; i++) {
      Color color = Colors.white.withOpacity(0.3);
      if (i < fullFish) {
        color = const Color(0xFF66CCCC);
      } else if (i == fullFish && lastFishOpacity > 0.1) {
        color = const Color(0xFF66CCCC).withOpacity(lastFishOpacity);
      }
      fishIcons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Icon(Icons.phishing, size: 30, color: color),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: fishIcons,
    );
  }
}