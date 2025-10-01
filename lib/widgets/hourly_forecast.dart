import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/forecast_data.dart';
import '../utils/weather_icon_mapper.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// ====================================================================
// NUOVO HELPER DI DEBUG PROATTIVO
// ====================================================================
class DebugPrintHelper {
  static void printValueAndType(Map<String, dynamic> dataMap, String key) {
    if (!kDebugMode) return;

    debugPrint('--- [VALUE DEBUG: Key="$key"] ---');

    // Controlliamo se la mappa contiene la chiave
    if (dataMap.containsKey(key)) {
      final value = dataMap[key];
      debugPrint('  -> Valore ricevuto: $value');
      debugPrint('  -> TIPO del valore: ${value.runtimeType}');

      // Tentiamo e logghiamo i cast
      try {
        debugPrint('  -> Risultato di "as String?": ${value as String?}');
      } catch (e) {
        debugPrint('  -> FALLIMENTO cast "as String?": $e');
      }
      try {
        debugPrint('  -> Risultato di "as num?": ${value as num?}');
      } catch (e) {
        debugPrint('  -> FALLIMENTO cast "as num?": $e');
      }
      debugPrint('  -> Risultato di ".toString()": ${value?.toString()}');
    } else {
      debugPrint(
          '  -> ERRORE: La chiave "$key" NON è presente nei dati ricevuti.');
    }
    debugPrint('----------------------------------');
  }
}
// ====================================================================

// ===============================================================
// WIDGET RIUTILIZZABILE PER LA VISUALIZZAZIONE A "PILLOLA"
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(text: value),
            TextSpan(
              text: ' $unit',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
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

  Color _getWindColor(double? speedKn) {
    if (speedKn == null) return Colors.white;
    if (speedKn < 12) return Colors.white;
    if (speedKn < 20) return Colors.yellow.shade600;
    if (speedKn < 30) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  Color _getWaveColor(double? meters) {
    if (meters == null) return Colors.transparent;
    Color color;
    if (meters < 0.2) {
      color = Colors.blueGrey.withOpacity(0.1);
    } else if (meters < 0.5) {
      color = Colors.blue.shade800.withOpacity(0.4);
    } else if (meters < 1.0) {
      color = Colors.blue.shade500.withOpacity(0.6);
    } else {
      color = Colors.indigo.shade400.withOpacity(0.8);
    }
    if (kDebugMode)
      debugPrint("[HEATMAP DEBUG] Wave Height: ${meters}m -> Color: $color");
    return color;
  }

  Color _getPrecipitationColor(double? mm) {
    if (mm == null || mm < 0.1) return Colors.transparent;
    Color color;
    if (mm < 0.5) {
      color = Colors.lightBlue.shade700.withOpacity(0.4);
    } else if (mm < 1.5) {
      color = Colors.lightBlue.shade400.withOpacity(0.6);
    } else {
      color = Colors.cyan.shade300.withOpacity(0.8);
    }
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

  // --- VISTA CONTRATTA ---
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

  // --- VISTA ESPANSA ---
  Widget _buildExpandedView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final listWidth = screenWidth - 45;
    const double itemWidth = 70.0;

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
            itemExtent: itemWidth,
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

  // --- COLONNA DATI (CON NUOVA LOGICA RICHTEXT E DEBUG) ---
  Widget _buildHourDataColumn(Map<String, dynamic> hour) {
    // CHIAMATA AL DEBUG HELPER: La prima cosa che facciamo è ispezionare il dato.
    DebugPrintHelper.printValueAndType(hour, 'currentSpeedKn');

    const double dataGridRowHeight = 28.0;
    const primaryDataStyle = TextStyle(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold);

    // Stile principale per dati secondari (il numero)
    const secondaryValueStyle = TextStyle(
        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold);
    // Stile per le unità di misura dei dati secondari (più leggere)
    final secondaryUnitStyle = secondaryValueStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: Colors.white.withOpacity(0.5));

    // Estrazione dei dati per la Heat Map e Wind
    final double waveHeight = (hour['waveHeight'] as num? ?? 0.0).toDouble();
    final double precipitation =
        (hour['precipitation'] as num? ?? 0.0).toDouble();
    final double windSpeed = (hour['windSpeedKn'] as num? ?? 0.0).toDouble();
    final double windDirection =
        (hour['windDirectionDegrees'] as num? ?? 0.0).toDouble();

    Widget buildDataRow(Widget child) {
      return SizedBox(height: dataGridRowHeight, child: Center(child: child));
    }

    // CHIAVE: Nuovo widget helper per i dati secondari con RichText
    Widget buildSecondaryDataRow(String value, String unit) {
      final bool isNotAvailable = (value == 'N/A' || value == 'N/D');

      return RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: <TextSpan>[
            TextSpan(
                // Usiamo il valore completo "N/A" per coerenza con il resto dell'app
                text: isNotAvailable ? 'N/A' : value,
                style: secondaryValueStyle),
            // Aggiungiamo l'unità di misura SOLO se il dato è disponibile
            if (!isNotAvailable)
              TextSpan(text: ' $unit', style: secondaryUnitStyle),
          ],
        ),
      );
    }

    Widget buildWindWidget() {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Transform.rotate(
            angle: (windDirection + 180) * math.pi / 180,
            child: Icon(Icons.navigation,
                size: 16, color: _getWindColor(windSpeed))),
        const SizedBox(width: 5),
        Text(windSpeed.round().toString(),
            style: primaryDataStyle.copyWith(color: _getWindColor(windSpeed))),
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
      // === DATI CRITICI ===
      buildDataRow(buildWindWidget()),
      // === DATI SECONDARI (con RichText) ===
      buildDataRow(buildSecondaryDataRow(
          (hour['pressure'] as num?)?.round().toString() ?? 'N/A', "hPa")),
      buildDataRow(
          buildSecondaryDataRow(hour['humidity']?.toString() ?? 'N/A', "%")),
      buildDataRow(buildSecondaryDataRow(
          (hour['precipitationProbability'] as num?)?.round().toString() ??
              'N/A',
          "%")),
      // === DATI CRITICI (con Heatmap) ===
      buildDataRow(
        DataPill(
          value: precipitation.toStringAsFixed(1),
          unit: "mm",
          backgroundColor: _getPrecipitationColor(precipitation),
        ),
      ),
      buildDataRow(
        DataPill(
          value: waveHeight.toStringAsFixed(1),
          unit: "m",
          backgroundColor: _getWaveColor(waveHeight),
        ),
      ),
      // === DATI PRIMARI ===
      buildDataRow(Text(
          "${(hour['waterTemperature'] as num?)?.round() ?? 'N/A'}°",
          style: primaryDataStyle)),

      // ===================================================================
      // CHIAVE: CODICE DI RENDERIZZAZIONE ROBUSTO
      // Il valore viene semplicemente convertito in String in modo sicuro.
      // ===================================================================
      buildDataRow(buildSecondaryDataRow(
          hour['currentSpeedKn']?.toString() ?? 'N/A', "kn")),
      // ===================================================================

      // === DATO PRIMARIO ===
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
