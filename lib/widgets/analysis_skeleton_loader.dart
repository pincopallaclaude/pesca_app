// lib/widgets/analysis_skeleton_loader.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AnalysisSkeletonLoader extends StatelessWidget {
  const AnalysisSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    // Colori per l'effetto shimmer, in linea con la palette "Premium Plus"
    final baseColor = Colors.grey.shade800;
    final highlightColor = Colors.grey.shade700;

    // Widget helper per creare una barra dello skeleton
    Widget _buildBar(
        {required double height, required double width, double radius = 4}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500), // Durata dell'animazione
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton per l'header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBar(height: 18, width: 18, radius: 9),
                const SizedBox(width: 8),
                _buildBar(height: 14, width: 120),
                const Spacer(),
                _buildBar(height: 20, width: 20, radius: 10),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(color: Colors.transparent),
            ),
            // Skeleton per il contenuto del testo
            const SizedBox(height: 16),
            _buildBar(height: 16, width: 100), // Titolo
            const SizedBox(height: 16),
            _buildBar(height: 12, width: double.infinity),
            const SizedBox(height: 8),
            _buildBar(height: 12, width: double.infinity),
            const SizedBox(height: 8),
            _buildBar(
                height: 12, width: MediaQuery.of(context).size.width * 0.5),
            const SizedBox(height: 24),
            _buildBar(height: 12, width: double.infinity),
            const SizedBox(height: 8),
            _buildBar(
                height: 12, width: MediaQuery.of(context).size.width * 0.7),
          ],
        ),
      ),
    );
  }
}
