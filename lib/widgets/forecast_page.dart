// /lib/widgets/forecast_page.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/forecast_data.dart';
import 'main_hero_module.dart';
import 'glassmorphism_card.dart';
import 'hourly_forecast.dart';
import 'weekly_forecast.dart';

class ForecastPage extends StatefulWidget {
  final ForecastData currentDayData;
  final String locationName;
  final VoidCallback onSearchTap;
  final bool isHourlyExpanded;
  final Function(bool) onHourlyExpansionChanged;
  final bool isToday;
  final List<ForecastData> weeklyForecastForDisplay;
  final bool isSunlightModeActive;
  final VoidCallback onAnalysisTap;

  const ForecastPage({
    super.key,
    required this.currentDayData,
    required this.locationName,
    required this.onSearchTap,
    required this.isHourlyExpanded,
    required this.onHourlyExpansionChanged,
    required this.isToday,
    required this.weeklyForecastForDisplay,
    required this.isSunlightModeActive,
    required this.onAnalysisTap,
  });

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;
  final List<Shadow> _sunlightTextShadows = [
    const Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 1)),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final newOpacity = (_scrollController.offset / 80).clamp(0.0, 1.0);
      if (newOpacity != _appBarOpacity && mounted) {
        setState(() => _appBarOpacity = newOpacity);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.2 * _appBarOpacity),
              ),
            ),
          ),
          elevation: 0,
          pinned: true,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          title: Text(widget.locationName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 22,
                shadows:
                    widget.isSunlightModeActive ? _sunlightTextShadows : null,
              )),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: widget.onSearchTap,
              ),
            )
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              MainHeroModule(
                data: widget.currentDayData,
                isSunlightModeActive: widget.isSunlightModeActive,
                onAnalysisTap: widget.onAnalysisTap,
              ),
              const SizedBox(height: 20),
              GlassmorphismCard(
                title: "PREVISIONI NELLE PROSSIME ORE",
                isExpandable: true,
                isExpanded: widget.isHourlyExpanded,
                onHeaderTap: () =>
                    widget.onHourlyExpansionChanged(!widget.isHourlyExpanded),
                padding: const EdgeInsets.all(20.0),
                child: HourlyForecast(
                  hourlyData: widget.isToday
                      ? widget.currentDayData.hourlyForecastForDisplay
                      : widget.currentDayData.hourlyData,
                  isExpanded: widget.isHourlyExpanded,
                ),
              ),
              const SizedBox(height: 20),
              GlassmorphismCard(
                title: "PREVISIONI PER I PROSSIMI GIORNI",
                padding: const EdgeInsets.all(20),
                child: WeeklyForecast(
                    forecastData: widget.weeklyForecastForDisplay),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
