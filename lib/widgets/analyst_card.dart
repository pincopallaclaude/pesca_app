// lib/widgets/analyst_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/analysis_viewmodel.dart';
import '../models/forecast_data.dart';
import 'analysis_view.dart';
import 'glassmorphism_card.dart';

class AnalystCard extends StatelessWidget {
  final double lat;
  final double lon;
  final VoidCallback onClose;
  final List<ForecastData> forecastData;

  const AnalystCard({
    super.key,
    required this.lat,
    required this.lon,
    required this.onClose,
    required this.forecastData,
  });

  @override
  Widget build(BuildContext context) {
    // Il contenitore che fornisce il ViewModel alla View
    return ChangeNotifierProvider(
      create: (_) => AnalysisViewModel(lat, lon),
      child: GlassmorphismCard(
        child: AnalysisView(onClose: onClose),
      ),
    );
  }
}
