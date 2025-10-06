// lib/screens/forecast_screen.dart

import 'dart:ui';
import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:light/light.dart'; // [THE FIX] Added the missing import

import '../models/forecast_data.dart';
import '../services/api_service.dart';
import '../widgets/main_hero_module.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/hourly_forecast.dart';
import '../widgets/weekly_forecast.dart';
import '../widgets/search_overlay.dart';
import '../widgets/location_services_dialog.dart';
import '../widgets/stale_data_dialog.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});
  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  Future<List<ForecastData>>? _forecastFuture;
  String _currentLocationName = "Posillipo";
  OverlayEntry? _searchOverlayEntry;
  bool _isLoadingGps = false;
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _isHourlyForecastExpanded = false;

  double _contrastOpacity = 0.3;
  final Map<String, double> _luminanceCache = {};

  StreamSubscription<int>? _lightSubscription;
  bool _isSunlightModeActive = false;
  static const int _sunlightThresholdLux = 7000;

  @override
  void initState() {
    super.initState();
    _loadForecast('40.813238367880984,14.208889980642137', "Posillipo");
    _initLightSensor();

    _pageController.addListener(() {
      final newPageIndex = _pageController.page?.round();
      if (newPageIndex != null && newPageIndex != _currentPageIndex) {
        if (!mounted) return;
        setState(() {
          _currentPageIndex = newPageIndex;
          _isHourlyForecastExpanded = false;
        });
        _updateContrastOpacityForPage(newPageIndex);
      }
    });
  }

  void _initLightSensor() {
    try {
      _lightSubscription = Light().lightSensorStream.listen((luxValue) {
        final isBright = luxValue > _sunlightThresholdLux;
        if (isBright != _isSunlightModeActive) {
          if (!mounted) return;
          setState(() {
            _isSunlightModeActive = isBright;
          });
        }
      }, onError: (error) {
        print("[Sunlight Mode] Errore stream sensore: $error");
        _lightSubscription?.cancel(); // Cancella in caso di errore
      });
    } catch (e) {
      print(
          "[Sunlight Mode] Impossibile avviare sensore (probabilmente non disponibile): $e");
    }
  }

  Future<void> _updateContrastOpacityForPage(int pageIndex) async {
    final forecasts = await _forecastFuture;
    if (forecasts == null || forecasts.isEmpty || pageIndex >= forecasts.length)
      return;
    final imagePath = forecasts[pageIndex].backgroundImagePath;
    if (_luminanceCache.containsKey(imagePath)) {
      if (!mounted) return;
      setState(() {
        _contrastOpacity = _luminanceCache[imagePath]!;
      });
      return;
    }
    final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
      AssetImage(imagePath),
      size: const Size(100, 100),
      maximumColorCount: 5,
    );
    final Color dominantColor = palette.dominantColor?.color ?? Colors.black;
    final double luminance = dominantColor.computeLuminance();
    final double newOpacity = (0.2 + (0.4 * luminance)).clamp(0.2, 0.6);
    _luminanceCache[imagePath] = newOpacity;
    if (!mounted) return;
    setState(() {
      _contrastOpacity = newOpacity;
    });
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _pageController.dispose();
    _searchOverlayEntry?.remove();
    super.dispose();
  }

  // All other _ForecastScreenState functions are unchanged
  void _loadForecast(String location, String name) {
    if (!mounted) return;
    setState(() {
      _currentLocationName = name;
      _forecastFuture = _apiService.fetchForecastData(location).catchError((e) {
        if (e is NetworkErrorWithStaleDataException && mounted) {
          showStaleDataDialog(context).then((useStaleData) {
            if (useStaleData == true) {
              setState(() {
                _forecastFuture = Future.value(
                    _apiService.parseForecastData(e.staleJsonData));
              });
            } else {
              setState(() {
                _forecastFuture = Future.error(Exception('Update rejected.'));
              });
            }
          });
        }
        throw e; // Re-throw the exception if it's not of the handled type
      });
    });
  }

  void _onGpsSearch() async {
    _removeSearchOverlay();
    if (!mounted) return;
    setState(() {
      _isLoadingGps = true;
    });
    try {
      final locationData = await _apiService.getCurrentGpsLocation();
      final coords = locationData['coords']!;
      final name = locationData['name']!;
      _loadForecast(coords, name);
    } on LocationServicesDisabledException {
      if (!mounted) return;
      showLocationServicesDialog(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll("Exception: ", "")),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
        });
      }
    }
  }

  void _onLocationSelected(String location, String name) {
    _removeSearchOverlay();
    _loadForecast(location, name);
  }

  void _toggleSearchPanel() {
    if (_searchOverlayEntry == null) {
      _searchOverlayEntry = _createSearchOverlay();
      Overlay.of(context).insert(_searchOverlayEntry!);
    } else {
      _removeSearchOverlay();
    }
  }

  void _removeSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  OverlayEntry _createSearchOverlay() {
    return OverlayEntry(
      builder: (context) => SearchOverlay(
        onClose: _toggleSearchPanel,
        onLocationSelected: _onLocationSelected,
        onGpsSearch: _onGpsSearch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingGps // Added _isLoadingGps check here
          ? Container(
              color: Colors.black,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)))
          : FutureBuilder<List<ForecastData>>(
              future: _forecastFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                      color: Colors.black,
                      child: const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white)));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.black54),
                          textAlign: TextAlign.center));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No data available.',
                          style: TextStyle(color: Colors.white)));
                }

                final forecasts = snapshot.data!;
                if (_luminanceCache.isEmpty && forecasts.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _updateContrastOpacityForPage(0));
                }
                final backgroundPath =
                    forecasts[_currentPageIndex].backgroundImagePath;

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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(_isSunlightModeActive
                                ? 0.75
                                : _contrastOpacity),
                            Colors.black.withOpacity(_isSunlightModeActive
                                ? 0.4
                                : _contrastOpacity * 0.5),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    PageView.builder(
                      controller: _pageController,
                      itemCount: forecasts.length,
                      itemBuilder: (context, index) {
                        final String todayFormatted =
                            DateFormat('dd/MM').format(DateTime.now());
                        final bool isActuallyToday =
                            forecasts[index].giornoData == todayFormatted;
                        final List<ForecastData> weeklyDisplayData =
                            (index + 1 < forecasts.length)
                                ? forecasts.skip(index + 1).toList()
                                : [];

                        return ForecastPage(
                          currentDayData: forecasts[index],
                          allForecasts: forecasts,
                          weeklyForecastForDisplay: weeklyDisplayData,
                          locationName: _currentLocationName,
                          onSearchTap: _toggleSearchPanel,
                          isHourlyExpanded: _isHourlyForecastExpanded,
                          onHourlyExpansionChanged: (isExpanded) {
                            setState(() {
                              _isHourlyForecastExpanded = isExpanded;
                            });
                          },
                          isToday: isActuallyToday,
                          isSunlightModeActive: _isSunlightModeActive,
                        );
                      },
                    )
                  ],
                );
              },
            ),
    );
  }
}

class ForecastPage extends StatefulWidget {
  final ForecastData currentDayData;
  final List<ForecastData> allForecasts;
  final String locationName;
  final VoidCallback onSearchTap;
  final bool isHourlyExpanded;
  final Function(bool) onHourlyExpansionChanged;
  final bool isToday;
  final List<ForecastData> weeklyForecastForDisplay;
  final bool isSunlightModeActive; // Added the new parameter

  const ForecastPage({
    super.key,
    required this.currentDayData,
    required this.allForecasts,
    required this.locationName,
    required this.onSearchTap,
    required this.isHourlyExpanded,
    required this.onHourlyExpansionChanged,
    required this.isToday,
    required this.weeklyForecastForDisplay,
    required this.isSunlightModeActive, // Added to the constructor
  });

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;
  // List of shadows to apply when Sunlight Mode is active
  final List<Shadow> _sunlightTextShadows = [
    const Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 1)),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final newOpacity = (_scrollController.offset / 80).clamp(0.0, 1.0);
      if (newOpacity != _appBarOpacity) {
        if (!mounted) return;
        setState(() {
          _appBarOpacity = newOpacity;
        });
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
          leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
          // Apply conditional shadow to the AppBar title
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
              // Pass the boolean to MainHeroModule as well
              MainHeroModule(
                  data: widget.currentDayData,
                  isSunlightModeActive: widget.isSunlightModeActive),
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
