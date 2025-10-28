// /lib/widgets/forecast_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/forecast_controller.dart';
import '../models/forecast_data.dart';
import 'forecast_page.dart'; // Importiamo il nuovo file ForecastPage

class ForecastView extends StatelessWidget {
  final ForecastController controller;
  final PageController pageController;
  final int currentPageIndex;
  final bool isHourlyForecastExpanded;
  final bool isAnalysisVisible;
  final bool isSunlightModeActive;
  final Function(int) onPageChanged;
  final Function(bool) onHourlyExpansionChanged;
  final VoidCallback onAnalysisTap;
  final VoidCallback onSearchTap;

  const ForecastView({
    super.key,
    required this.controller,
    required this.pageController,
    required this.currentPageIndex,
    required this.isHourlyForecastExpanded,
    required this.isAnalysisVisible,
    required this.isSunlightModeActive,
    required this.onPageChanged,
    required this.onHourlyExpansionChanged,
    required this.onAnalysisTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.forecastData == null) {
      return Container(
          color: Colors.black,
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)));
    }

    if (controller.errorMessage.isNotEmpty && controller.forecastData == null) {
      return Center(
          child: Text(controller.errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center));
    }

    final forecasts = controller.forecastData;
    if (forecasts == null || forecasts.isEmpty) {
      return const Center(
          child: Text('Nessun dato disponibile.',
              style: TextStyle(color: Colors.white)));
    }

    final backgroundPath = forecasts[currentPageIndex].backgroundImagePath;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image & PageView
        _buildForecastPages(forecasts, backgroundPath),
      ],
    );
  }

  Widget _buildForecastPages(
      List<ForecastData> forecasts, String backgroundPath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Image.asset(backgroundPath,
              key: ValueKey(backgroundPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity),
        ),
        IgnorePointer(
          ignoring: !isSunlightModeActive,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            opacity: isSunlightModeActive ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0.0, 0.8),
                  colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        PageView.builder(
          controller: pageController,
          itemCount: forecasts.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            final String todayFormatted =
                DateFormat('dd/MM').format(DateTime.now());
            final bool isActuallyToday =
                forecasts[index].giornoData == todayFormatted;

            return ForecastPage(
              currentDayData: forecasts[index],
              weeklyForecastForDisplay: (index + 1 < forecasts.length)
                  ? forecasts.skip(index + 1).toList()
                  : [],
              locationName: controller.currentLocationName,
              onSearchTap: onSearchTap,
              isHourlyExpanded: isHourlyForecastExpanded,
              onHourlyExpansionChanged: onHourlyExpansionChanged,
              isToday: isActuallyToday,
              isSunlightModeActive: isSunlightModeActive,
              onAnalysisTap: onAnalysisTap,
            );
          },
        ),
      ],
    );
  }
}
