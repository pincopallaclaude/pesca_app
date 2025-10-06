// lib/widgets/hourly_forecast.dart

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:weather_icons/weather_icons.dart';
import '../utils/weather_icon_mapper.dart';

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
    final isDarkBackground = backgroundColor.computeLuminance() < 0.4;
    final textColor =
        isDarkBackground ? Colors.white : Colors.black.withOpacity(0.9);

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
                fontSize: 10,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HourlyForecast extends StatefulWidget {
  final List<dynamic> hourlyData;
  final bool isExpanded;
  final int? dayIndex;

  const HourlyForecast({
    super.key,
    required this.hourlyData,
    required this.isExpanded,
    this.dayIndex,
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
        _animationController.forward(from: 0.0);
      } else {
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

  Color _lerpColor(
      Color minColor, Color maxColor, double value, double min, double max) {
    if (value <= min) return minColor;
    if (value >= max) return maxColor;
    final double t = (value - min) / (max - min);
    return Color.lerp(minColor, maxColor, t)!;
  }

  Color _getWindColor(double? speedKn) {
    final safeSpeedKn = speedKn ?? 0.0;
    if (safeSpeedKn < 1) return Colors.white;
    if (safeSpeedKn > 35) return Colors.purple.shade900;
    const Color green = Color(0xFF4CAF50);
    const Color yellow = Color(0xFFFFEB3B);
    const Color orange = Color(0xFFFF9800);
    const Color red = Color(0xFFF44336);
    if (safeSpeedKn < 10) return _lerpColor(green, yellow, safeSpeedKn, 1, 10);
    if (safeSpeedKn < 20)
      return _lerpColor(yellow, orange, safeSpeedKn, 10, 20);
    if (safeSpeedKn < 30) return _lerpColor(orange, red, safeSpeedKn, 20, 30);
    return _lerpColor(red, Colors.purple.shade900, safeSpeedKn, 30, 35);
  }

  Color _getPrecipitationProbabilityColor(double? probability) {
    if (probability == null || probability < 10) return Colors.white70;
    return _lerpColor(Colors.white70, Colors.cyanAccent, probability, 10, 100);
  }

  Color _getNewPrecipitationColor(double? mm) {
    if (mm == null || mm < 0.1) return Colors.transparent;
    const medColor = Colors.blue;
    const maxColor = Colors.indigo;
    return (mm < 2.0)
        ? _lerpColor(Colors.transparent, medColor, mm, 0.1, 2.0)
        : _lerpColor(medColor, maxColor, mm, 2.0, 10.0);
  }

  Color _getNewWaveColor(double? meters) {
    if (meters == null || meters < 0.2) return Colors.transparent;
    const lightWave = Color(0x9929B6F6);
    const medWave = Color(0xB30091EA);
    if (meters <= 1.0)
      return _lerpColor(Colors.transparent, lightWave, meters, 0.2, 1.0);
    return _lerpColor(lightWave, medWave, meters, 1.0, 2.5);
  }

  // [LA SOLUZIONE È QUI] Aggiunta della nuova funzione per l'umidità
  Color _getHumidityColor(double? humidity) {
    if (humidity == null) return Colors.white70;
    const dryColor = Color(0xFFFBC02D);
    const comfortColor = Colors.white70;
    const humidColor = Color(0xFF4DD0E1);
    const veryHumidColor = Color(0xFF26A69A);
    if (humidity < 30)
      return _lerpColor(dryColor, comfortColor, humidity, 0, 30);
    if (humidity >= 30 && humidity <= 60) return comfortColor;
    if (humidity > 60 && humidity <= 85)
      return _lerpColor(comfortColor, humidColor, humidity, 60, 85);
    return _lerpColor(humidColor, veryHumidColor, humidity, 85, 100);
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

  Widget _buildContractedView() {
    if (widget.hourlyData.isEmpty) {
      return const Center(
          child: Text('Nessun dato orario disponibile',
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: widget.hourlyData.length,
      itemBuilder: (context, index) {
        final hour = widget.hourlyData[index] as Map<String, dynamic>;
        final time = (hour['time'] as String?)?.split(':')[0] ?? '--';
        final weatherCode = hour['weatherCode'] as String? ?? '0';
        final isDay = hour['isDay'] as bool? ?? true;
        final tempC = (hour['tempC'] as num?)?.round() ?? 'N/A';

        return Container(
          width: 65,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(time,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              BoxedIcon(
                getWeatherIcon(weatherCode, isDay: isDay),
                color: getWeatherIconColor(weatherCode, isDay: isDay),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text("$tempC°",
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

  Widget _buildExpandedView() {
    if (widget.hourlyData.isEmpty) {
      return const Center(
          child: Text('Nessun dato orario disponibile',
              style: TextStyle(color: Colors.white70)));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 45, child: _buildLabelsColumn()),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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

  Widget _buildLabelsColumn() {
    const double dataGridRowHeight = 28.0;
    const iconColor = Colors.white70;
    const secondaryIconColor = Colors.white38;

    final List<Widget> labelRows = [
      const SizedBox(height: 105),
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Divider(color: Colors.white24, height: 1)),
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
          AnimationLimiter(
            child: Column(
              children: labelRows.map((row) {
                final index = labelRows.indexOf(row);
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 250),
                  child: SlideAnimation(
                      verticalOffset: 20.0, child: FadeInAnimation(child: row)),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHourDataColumn(Map<String, dynamic> hour) {
    const double dataGridRowHeight = 28.0;
    const primaryDataStyle = TextStyle(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold);
    const secondaryDataStyle = TextStyle(
        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold);

    final double waveHeight =
        ((hour['waveHeight'] as num? ?? 0.0) * 10).round() / 10.0;
    final double precipitation =
        ((hour['precipitation'] as num? ?? 0.0) * 10).round() / 10.0;
    final double precipProbability =
        (hour['precipitationProbability'] as num? ?? 0.0).toDouble();
    final double windSpeed = (hour['windSpeedKn'] as num? ?? 0.0).toDouble();
    final double windDirection =
        (hour['windDirectionDegrees'] as num? ?? 0.0).toDouble();
    final double humidity =
        (hour['humidity'] as num? ?? 0.0).toDouble(); // Estrazione umidità

    Widget buildDataRow(Widget child) =>
        SizedBox(height: dataGridRowHeight, child: Center(child: child));

    Widget buildWindWidget() {
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
      buildDataRow(buildWindWidget()),
      buildDataRow(RichText(
          text: TextSpan(children: [
        TextSpan(
            text: (hour['pressure'] as num?)?.round().toString() ?? 'N/A',
            style: secondaryDataStyle.copyWith(fontSize: 13)),
        TextSpan(
            text: ' hPa',
            style: secondaryDataStyle.copyWith(
                fontSize: 11, color: Colors.white38))
      ]))),

      // [LA SOLUZIONE È QUI] Applichiamo la nuova funzione allo stile del testo
      buildDataRow(RichText(
        text: TextSpan(
          style:
              secondaryDataStyle.copyWith(color: _getHumidityColor(humidity)),
          children: [
            TextSpan(text: humidity.round().toString()),
            TextSpan(
                text: '%',
                style: TextStyle(
                    fontSize: 11,
                    color: _getHumidityColor(humidity).withOpacity(0.7))),
          ],
        ),
      )),

      buildDataRow(RichText(
          text: TextSpan(children: [
        TextSpan(
            text: precipProbability.round().toString(),
            style: primaryDataStyle.copyWith(
                color: precipitation > 0.09
                    ? _getPrecipitationProbabilityColor(precipProbability)
                    : primaryDataStyle.color)),
        TextSpan(
            text: '%',
            style: primaryDataStyle.copyWith(
                fontSize: 11,
                color: (precipitation > 0.09
                        ? _getPrecipitationProbabilityColor(precipProbability)
                        : primaryDataStyle.color)!
                    .withOpacity(0.7)))
      ]))),
      buildDataRow(DataPill(
          value: precipitation.toStringAsFixed(1),
          unit: "mm",
          backgroundColor: _getNewPrecipitationColor(precipitation))),
      buildDataRow(DataPill(
          value: waveHeight.toStringAsFixed(1),
          unit: "m",
          backgroundColor: _getNewWaveColor(waveHeight))),
      buildDataRow(RichText(
          text: TextSpan(children: [
        TextSpan(
            text:
                (hour['waterTemperature'] as num?)?.round().toString() ?? 'N/A',
            style: primaryDataStyle),
        TextSpan(
            text: '°',
            style: primaryDataStyle.copyWith(
                fontSize: 11, color: primaryDataStyle.color!.withOpacity(0.7)))
      ]))),
      buildDataRow(RichText(
          text: TextSpan(children: [
        TextSpan(
            text: hour['currentSpeedKn']?.toString() ?? 'N/A',
            style: secondaryDataStyle.copyWith(fontSize: 13)),
        TextSpan(
            text: ' kn',
            style: secondaryDataStyle.copyWith(
                fontSize: 11, color: Colors.white38))
      ]))),
      buildDataRow(FittedBox(
          fit: BoxFit.scaleDown,
          child: Text((hour['tide'] as String?)?.split(' ')[0] ?? '',
              style: primaryDataStyle.copyWith(fontSize: 10)))),
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
                        child: FadeInAnimation(child: dataRows[index])),
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
