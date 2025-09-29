// lib/screens/weekly_forecast.dart

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/forecast_data.dart';
import '../utils/weather_icon_mapper.dart';
import 'package:weather_icons/weather_icons.dart';

class WeeklyForecast extends StatefulWidget {
  final List<ForecastData> forecastData;

  const WeeklyForecast({super.key, required this.forecastData});

  @override
  State<WeeklyForecast> createState() => _WeeklyForecastState();
}

class _WeeklyForecastState extends State<WeeklyForecast> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox leggermente più largo per ospitare la "pillola"
          SizedBox(
            width: 60,
            child: _buildAnimatedDayColumn(context, widget.forecastData),
          ),
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [Colors.transparent, Colors.white],
                  stops: const [0.0, 0.05],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: _buildDataTable(context, widget.forecastData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDayColumn(
      BuildContext context, List<ForecastData> data) {
    return Column(
      children: data.asMap().entries.map((entry) {
        int index = entry.key;
        final bool isSelected = _selectedIndex == index;
        final double opacity =
            (_selectedIndex != null && !isSelected) ? 0.6 : 1.0;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: opacity,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                // La "Pillola" indicatore
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  width: isSelected
                      ? 4.0
                      : 0.0, // Appare/scompare animando la larghezza
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                // Spaziatura tra pillola e testo
                const SizedBox(width: 8.0),
                Text(
                  data[index].giornoNome.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataTable(BuildContext context, List<ForecastData> data) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.asMap().entries.map((entry) {
          int index = entry.key;
          ForecastData dayData = entry.value;
          return _buildForecastRow(context, dayData, index);
        }).toList(),
      ),
    );
  }

  Widget _buildForecastRow(BuildContext context, ForecastData data, int index) {
    final bool isSelected = _selectedIndex == index;
    final double opacity = (_selectedIndex != null && !isSelected) ? 0.6 : 1.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIndex = null;
          } else {
            _selectedIndex = index;
            HapticFeedback.lightImpact();
          }
        });
      },
      // Impostiamo uno sfondo trasparente per evitare che la riga intercetti
      // i tocchi solo dove c'è contenuto visibile
      behavior: HitTestBehavior.translucent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: Container(
          height: 52,
          // Rimuoviamo il colore di sfondo della selezione da qui
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              // Il bordo è sempre uguale per tutte le righe
              bottom:
                  BorderSide(color: Colors.white.withOpacity(0.1), width: 1.0),
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTableCell(_buildScoreCell(data.pescaScoreNumeric.round()),
                    width: 60),
                _buildTableCell(
                  BoxedIcon(
                    getWeatherIcon(data.dailyWeatherCode, isDay: true),
                    color:
                        getWeatherIconColor(data.dailyWeatherCode, isDay: true),
                    size: 28,
                  ),
                  width: 50,
                ),
                _buildTableCell(
                    _buildTempCell(data.temperaturaMax, data.temperaturaMin),
                    width: 50),
                _buildTableCell(
                    _buildWindCell(
                        data.dailyWindSpeedKn, data.dailyWindDirectionDegrees),
                    width: 75),
                _buildTableCell(_buildHumidityCell(data.dailyHumidity),
                    width: 75),
                _buildTableCell(
                    _buildPressureCell(data.dailyPressure, data.trendPressione),
                    width: 95),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCell(int score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.phishing, color: Colors.cyan, size: 20),
        const SizedBox(width: 6),
        Text(score.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTempCell(double max, double min) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("${max.round()}°",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text("${min.round()}°", style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildWindCell(int speed, int degrees) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: (degrees * math.pi / 180) + (math.pi),
          child: const Icon(Icons.navigation, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 5),
        Text("$speed kn", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHumidityCell(int humidity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.water_drop_outlined, color: Colors.blue.shade200, size: 18),
        const SizedBox(width: 5),
        Text("$humidity%", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPressureCell(int pressure, String trend) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("$pressure hPa",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        _getPressureTrendIcon(trend),
      ],
    );
  }

  Widget _buildTableCell(Widget child, {required double width}) {
    return SizedBox(
      width: width,
      child: Center(child: child),
    );
  }

  Widget _getPressureTrendIcon(String trend) {
    switch (trend) {
      case '↑':
        return const Icon(Icons.arrow_upward, color: Colors.white70, size: 20);
      case '↓':
        return const Icon(Icons.arrow_downward, color: Colors.cyan, size: 20);
      default:
        return const Icon(Icons.arrow_forward, color: Colors.white70, size: 20);
    }
  }
}
