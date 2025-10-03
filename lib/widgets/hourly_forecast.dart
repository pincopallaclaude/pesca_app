// lib/screens/hourly_forecast.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/forecast_data.dart';
import '../utils/weather_icon_mapper.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// ===============================================================
// WIDGET RIUTILIZZABILE PER LA VISUALIZZAZIONE A "PILLOLA" (AGGIORNATO)
// ===============================================================
class DataPill extends StatelessWidget {
  final String value;
  final String unit;
  final Color backgroundColor;

  const DataPill({
    super.key,
    required this.value,
    required this.unit,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    // Aggiungiamo un colore di testo in contrasto per gli sfondi più scuri
    final isDarkBackground = backgroundColor.computeLuminance() < 0.4;
    final textColor =
        isDarkBackground ? Colors.white : Colors.white.withOpacity(0.9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(text: value),
            TextSpan(
              text: ' $unit',
              style: TextStyle(
                fontSize: 10, // Riduci la dimensione a 10
                color: textColor.withOpacity(0.5), // Rendi l'unità PIÙ sbiadita
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ===============================================================

class HourlyForecast extends StatefulWidget {
  final List<dynamic> hourlyData;
  final bool isExpanded;

  const HourlyForecast({
    super.key,
    required this.hourlyData,
    required this.isExpanded,
  });

  @override
  State<HourlyForecast> createState() => _HourlyForecastState();
}

class _HourlyForecastState extends State<HourlyForecast>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant HourlyForecast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        if (kDebugMode)
          debugPrint("[ANIMATION DEBUG] Starting animation forward...");
        _animationController.forward(from: 0.0);
      } else {
        if (kDebugMode) debugPrint("[ANIMATION DEBUG] Resetting animation...");
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- FUNZIONI HELPER PER COLORI DINAMICI (HEAT MAP) ---

  // Funzione helper per l'interpolazione lineare dei colori
  Color _lerpColor(
      Color minColor, Color maxColor, double value, double min, double max) {
    if (value <= min) return minColor;
    if (value >= max) return maxColor;
    final double t = (value - min) / (max - min);
    return Color.lerp(minColor, maxColor, t)!;
  }

  // --- NUOVO GRADIENTE LISCIO MULTI-STOP PER IL VENTO ---
  Color _getWindColor(double? speedKn) {
    if (speedKn == null || speedKn < 1)
      return Colors.white; // Bianco sotto 1 nodo
    if (speedKn > 35)
      return Colors.purple.shade900; // Colore massimo di allerta

    // Definiamo i punti chiave del nostro gradiente
    const Color green = Color(0xFF4CAF50); // Verde per venti leggeri (~5kn)
    const Color yellow = Color(0xFFFFEB3B); // Giallo per venti moderati (~15kn)
    const Color orange = Color(0xFFFF9800); // Arancione per venti tesi (~25kn)
    const Color red = Color(0xFFF44336); // Rosso per venti forti (~35kn)

    Color color;
    if (speedKn < 10) {
      color = _lerpColor(green, yellow, speedKn, 1, 10);
    } else if (speedKn < 20) {
      color = _lerpColor(yellow, orange, speedKn, 10, 20);
    } else if (speedKn < 30) {
      color = _lerpColor(orange, red, speedKn, 20, 30);
    } else {
      color = _lerpColor(red, Colors.purple.shade900, speedKn, 30, 35);
    }

    if (kDebugMode)
      debugPrint(
          "[WIND GRADIENT DEBUG] Speed: ${speedKn.toStringAsFixed(1)}kn -> Calculated Color: $color");
    return color;
  }

  // --- GRADIENTE LISCIO PER LE ONDE (INVARIANTI NELLA LOGICA) ---
  Color _getWaveColor(double? meters) {
    if (meters == null) return Colors.transparent;
    final medColor = Colors.blue.shade800.withOpacity(0.5);
    final maxColor = Colors.indigo.shade300.withOpacity(0.8);

    Color color = (meters < 0.5)
        ? _lerpColor(Colors.transparent, medColor, meters, 0.0, 0.5)
        : _lerpColor(medColor, maxColor, meters, 0.5, 1.5);

    if (kDebugMode)
      debugPrint("[HEATMAP DEBUG] Wave Height: ${meters}m -> Color: $color");
    return color;
  }

  // --- GRADIENTE LISCIO PER LE PRECIPITAZIONI (INVARIANTI NELLA LOGICA) ---
  Color _getPrecipitationColor(double? mm) {
    if (mm == null || mm < 0.1) return Colors.transparent;
    final maxColor = Colors.cyan.shade200.withOpacity(0.8);
    Color color = _lerpColor(Colors.transparent, maxColor, mm, 0.0, 2.5);

    if (kDebugMode)
      debugPrint("[HEATMAP DEBUG] Precipitation: ${mm}mm -> Color: $color");
    return color;
  }

  @override
  Widget build(BuildContext context) {
    const double expandedHeight = 380.0;
    const double contractedHeight = 110.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      height: widget.isExpanded ? expandedHeight : contractedHeight,
      child: ClipRect(
        child:
            widget.isExpanded ? _buildExpandedView() : _buildContractedView(),
      ),
    );
  }

  // --- VISTA CONTRATTA (INVARIATA) ---
  Widget _buildContractedView() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: widget.hourlyData.length,
      itemBuilder: (context, index) {
        final hour = widget.hourlyData[index] as Map<String, dynamic>;
        return Container(
          width: 65,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text((hour['time'] as String?)?.split(':')[0] ?? '--',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              BoxedIcon(
                getWeatherIcon(hour['weatherCode'] as String? ?? '0',
                    isDay: hour['isDay'] as bool? ?? true),
                color: getWeatherIconColor(
                    hour['weatherCode'] as String? ?? '0',
                    isDay: hour['isDay'] as bool? ?? true),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text("${(hour['tempC'] as num?)?.round() ?? 'N/A'}°",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  // --- VISTA ESPANSA (INVARIATA) ---
  Widget _buildExpandedView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 45, child: _buildLabelsColumn()),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const PageScrollPhysics(),
            itemCount: widget.hourlyData.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              final hour = widget.hourlyData[index] as Map<String, dynamic>;
              return _buildHourDataColumn(hour);
            },
          ),
        ),
      ],
    );
  }

  // --- COLONNA ETICHETTE (INVARIATA) ---
  Widget _buildLabelsColumn() {
    const double dataGridRowHeight = 28.0;
    const iconColor = Colors.white70;
    const secondaryIconColor = Colors.white38;

    final List<Widget> labelRows = [
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child:
                  Icon(WeatherIcons.strong_wind, size: 18, color: iconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child: Icon(Icons.speed, size: 18, color: secondaryIconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child: Icon(Icons.water_drop_outlined,
                  size: 18, color: secondaryIconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child: BoxedIcon(WeatherIcons.raindrop,
                  size: 22, color: iconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child: BoxedIcon(WeatherIcons.raindrops,
                  size: 22, color: iconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child:
                  BoxedIcon(WeatherIcons.tsunami, size: 22, color: iconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child: BoxedIcon(WeatherIcons.thermometer,
                  size: 22, color: iconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child: Icon(Icons.trending_flat,
                  size: 18, color: secondaryIconColor))),
      SizedBox(
          height: dataGridRowHeight,
          child: Center(
              child:
                  BoxedIcon(WeatherIcons.time_10, size: 22, color: iconColor))),
    ];

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 105),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(color: Colors.white24, height: 1)),
          AnimationLimiter(
            child: Column(
              children: List.generate(labelRows.length, (index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 250),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(
                      child: labelRows[index],
                    ),
                  ),
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  // --- COLONNA DATI (ADATTATA CON NUOVO GRADIENTE VENTO) ---
  Widget _buildHourDataColumn(Map<String, dynamic> hour) {
    const double dataGridRowHeight = 28.0;
    const primaryDataStyle = TextStyle(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold);
    const secondaryDataStyle = TextStyle(
        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold);

    // Estrazione e arrotondamento dei dati
    final double waveHeight =
        ((hour['waveHeight'] as num? ?? 0.0) * 10).round() / 10.0;
    final double precipitation =
        ((hour['precipitation'] as num? ?? 0.0) * 10).round() / 10.0;

    final double windSpeed = (hour['windSpeedKn'] as num? ?? 0.0).toDouble();
    final double windDirection =
        (hour['windDirectionDegrees'] as num? ?? 0.0).toDouble();

    Widget buildDataRow(Widget child) {
      return SizedBox(height: dataGridRowHeight, child: Center(child: child));
    }

    Widget buildWindWidget() {
      // Uso della nuova logica _getWindColor per l'icona e il testo
      final windColor = _getWindColor(windSpeed);
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Transform.rotate(
            angle: (windDirection + 180) * math.pi / 180,
            child: Icon(Icons.navigation, size: 16, color: windColor)),
        const SizedBox(width: 5),
        Text(windSpeed.round().toString(),
            style: primaryDataStyle.copyWith(color: windColor)),
      ]);
    }

    Widget headerBlock = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text((hour['time'] as String?)?.split(':')[0] ?? '--',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 8),
        BoxedIcon(
          getWeatherIcon(hour['weatherCode'] as String? ?? '0',
              isDay: hour['isDay'] as bool? ?? true),
          color: getWeatherIconColor(hour['weatherCode'] as String? ?? '0',
              isDay: hour['isDay'] as bool? ?? true),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text("${(hour['tempC'] as num?)?.round() ?? 'N/A'}°",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const Spacer(),
      ],
    );

    final List<Widget> dataRows = [
      // Wind Speed + Direction (INVARIATO)
      buildDataRow(buildWindWidget()),
      // Pressure (APPLICATO RichText)
      buildDataRow(RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: (hour['pressure'] as num?)?.round().toString() ?? 'N/A',
                style: secondaryDataStyle.copyWith(
                    fontSize: 13)), // AUMENTATO font size a 13
            TextSpan(
                text: ' hPa',
                style: secondaryDataStyle.copyWith(
                    fontSize: 11, color: Colors.white38)),
          ],
        ),
      )),
      // Humidity (APPLICATO RichText per effetto premium)
      buildDataRow(RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: hour['humidity']?.toString() ?? 'N/A',
                style: secondaryDataStyle.copyWith(
                    fontSize: 13)), // AUMENTATO font size a 13
            TextSpan(
                text: '%',
                style: secondaryDataStyle.copyWith(
                    fontSize: 11, color: Colors.white38)),
          ],
        ),
      )),
      // Precipitation Probability (APPLICATO RichText per effetto premium e coerenza)
      buildDataRow(RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: (hour['precipitationProbability'] as num?)
                        ?.round()
                        .toString() ??
                    'N/A',
                style: primaryDataStyle.copyWith(fontSize: 13)),
            TextSpan(
                text: '%',
                style: primaryDataStyle.copyWith(
                    fontSize: 11,
                    color: primaryDataStyle.color!.withOpacity(0.7))),
          ],
        ),
      )),
      // Precipitation (USA DataPill, GIA' CORRETTO)
      buildDataRow(
        DataPill(
          value: precipitation.toStringAsFixed(1),
          unit: "mm",
          backgroundColor: _getPrecipitationColor(precipitation),
        ),
      ),
      // Wave Height (USA DataPill, GIA' CORRETTO)
      buildDataRow(
        DataPill(
          value: waveHeight.toStringAsFixed(1),
          unit: "m",
          backgroundColor: _getWaveColor(waveHeight),
        ),
      ),
      // Water Temperature (APPLICATO RichText per effetto premium)
      buildDataRow(RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: (hour['waterTemperature'] as num?)?.round().toString() ??
                    'N/A',
                style: primaryDataStyle),
            TextSpan(
                text: '°',
                style: primaryDataStyle.copyWith(
                    fontSize: 11,
                    color: primaryDataStyle.color!.withOpacity(0.7))),
          ],
        ),
      )),
      // Current Speed (APPLICATO RichText)
      buildDataRow(RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: hour['currentSpeedKn']?.toString() ?? 'N/A',
                style: secondaryDataStyle.copyWith(
                    fontSize: 13)), // AUMENTATO font size a 13
            TextSpan(
                text: ' kn',
                style: secondaryDataStyle.copyWith(
                    fontSize: 11, color: Colors.white38)),
          ],
        ),
      )),
      // Tide (INVARIATO)
      buildDataRow(
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text((hour['tide'] as String?)?.split(' ')[0] ?? '',
              style: primaryDataStyle.copyWith(fontSize: 10)),
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
          border: Border(
              left: BorderSide(
                  color: Colors.white.withOpacity(0.1), width: 1.0))),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 105, child: headerBlock),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Divider(color: Colors.white24, height: 1)),
            AnimationLimiter(
              child: Column(
                children: List.generate(dataRows.length, (index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 250),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: dataRows[index],
                      ),
                    ),
                  );
                }),
              ),
            )
          ],
        ),
      ),
    );
  }
}
