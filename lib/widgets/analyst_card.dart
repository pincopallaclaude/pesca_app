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
    return ChangeNotifierProvider(
      create: (_) => AnalysisViewModel(lat, lon)..fetchAnalysisWithDelay(),
      child: AnalysisView(
          onClose: onClose), // AnalysisView gestisce già lo stile Blue Glass
    );
  }
}
