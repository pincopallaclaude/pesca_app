// lib/screens/forecast_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:light/light.dart';

import '../models/forecast_data.dart';
import '../services/api_service.dart';
import '../widgets/analyst_card.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/hourly_forecast.dart';
import '../widgets/location_services_dialog.dart';
import '../widgets/main_hero_module.dart';
import '../widgets/search_overlay.dart';
import '../widgets/weekly_forecast.dart';
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
  bool _isAnalysisVisible = false;
  StreamSubscription<int>? _lightSubscription;
  bool _isSunlightModeActive = false;
  static const int _sunlightThresholdLux = 7000;

  @override
  void initState() {
    super.initState();
    _loadForecast('40.813,14.208', "Posillipo");
    _initLightSensor();
    _pageController.addListener(() {
      final newPageIndex = _pageController.page?.round();
      if (newPageIndex != null && newPageIndex != _currentPageIndex) {
        if (mounted) {
          setState(() {
            _currentPageIndex = newPageIndex;
            _isHourlyForecastExpanded = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _pageController.dispose();
    _searchOverlayEntry?.remove();
    super.dispose();
  }

  void _initLightSensor() {
    try {
      _lightSubscription = Light().lightSensorStream.listen((luxValue) {
        final isBright = luxValue > _sunlightThresholdLux;
        if (isBright != _isSunlightModeActive && mounted) {
          setState(() => _isSunlightModeActive = isBright);
        }
      });
    } catch (e) {
      print("[Sunlight Mode] Could not start sensor: $e");
    }
  }

  void _loadForecast(String location, String name) {
    if (!mounted) return;
    setState(() {
      _currentLocationName = name;
      _forecastFuture = _apiService.fetchForecastData(location).catchError((e) {
        if (e is NetworkErrorWithStaleDataException && mounted) {
          showStaleDataDialog(context).then((useStaleData) {
            if (useStaleData == true && mounted) {
              setState(() {
                _forecastFuture = Future.value(
                    _apiService.parseForecastData(e.staleJsonData));
              });
            } else if (mounted) {
              setState(() {
                _forecastFuture =
                    Future.error(Exception('Update rejected by user.'));
              });
            }
          });
        }
        throw e;
      });
    });
  }

  void _onGpsSearch() async {
    _removeSearchOverlay();
    if (!mounted) return;
    setState(() => _isLoadingGps = true);
    try {
      final locationData = await _apiService.getCurrentGpsLocation();
      _loadForecast(locationData['coords']!, locationData['name']!);
    } on LocationServicesDisabledException {
      if (mounted) showLocationServicesDialog(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGps = false);
      }
    }
  }

  void _onLocationSelected(String location, String name) {
    _removeSearchOverlay();
    _loadForecast(location, name);
  }

  void _toggleAnalysis() {
    setState(() => _isAnalysisVisible = !_isAnalysisVisible);
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
      body: _isLoadingGps
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
                final backgroundPath =
                    forecasts[_currentPageIndex].backgroundImagePath;
                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    Stack(
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
                          ignoring: !_isSunlightModeActive,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            opacity: _isSunlightModeActive ? 1.0 : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: const Alignment(0.0, 0.8),
                                  colors: [
                                    Colors.black.withOpacity(0.75),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        PageView.builder(
                          controller: _pageController,
                          itemCount: forecasts.length,
                          onPageChanged: (index) {
                            if (mounted) {
                              setState(() {
                                _currentPageIndex = index;
                                _isHourlyForecastExpanded = false;
                              });
                            }
                          },
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
                                if (mounted)
                                  setState(() =>
                                      _isHourlyForecastExpanded = isExpanded);
                              },
                              isToday: isActuallyToday,
                              isSunlightModeActive: _isSunlightModeActive,
                              onAnalysisTap: _toggleAnalysis,
                            );
                          },
                        )
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _isAnalysisVisible
                          ? BackdropFilter(
                              key: const ValueKey('blur'),
                              filter:
                                  ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                  color: Colors.black.withOpacity(0.2)),
                            )
                          : const SizedBox.shrink(key: ValueKey('no-blur')),
                    ),
                    if (_isAnalysisVisible)
                      GestureDetector(
                        onTap: _toggleAnalysis,
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 400),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isAnalysisVisible
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 60.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.75,
                                  ),
                                  child: AnalystCard(
                                    key: ValueKey(
                                        "analysis_card_$_currentPageIndex"),
                                    lat: 40.813,
                                    lon: 14.208,
                                    onClose: _toggleAnalysis,
                                    forecastData: forecasts,
                                  ),
                                ),
                              ))
                          : const SizedBox.shrink(key: ValueKey("empty_card")),
                    ),
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
  final bool isSunlightModeActive;
  final VoidCallback onAnalysisTap;

  const ForecastPage(
      {super.key,
      required this.currentDayData,
      required this.allForecasts,
      required this.locationName,
      required this.onSearchTap,
      required this.isHourlyExpanded,
      required this.onHourlyExpansionChanged,
      required this.isToday,
      required this.weeklyForecastForDisplay,
      required this.isSunlightModeActive,
      required this.onAnalysisTap});
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
          leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
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
