// lib/screens/forecast_screen.dart

import 'dart:async'; // Dart SDK
import 'dart:ui'; // Dart SDK
import 'package:flutter/material.dart'; // Flutter
import 'package:light/light.dart'; // Package esterni
import 'package:intl/intl.dart'; // Package esterni

import '../models/forecast_data.dart'; // Relativi
import '../services/api_service.dart'; // Relativi
import '../widgets/analyst_card.dart'; // Relativi
import '../widgets/glassmorphism_card.dart'; // Relativi
import '../widgets/hourly_forecast.dart'; // Relativi
import '../widgets/location_services_dialog.dart'; // Relativi
import '../widgets/main_hero_module.dart'; // Relativi
import '../widgets/search_overlay.dart'; // Relativi
import '../widgets/stale_data_dialog.dart'; // Relativi
import '../widgets/weekly_forecast.dart'; // Relativi

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

  StreamSubscription<int>? _lightSubscription;
  bool _isSunlightModeActive = false;
  static const int _sunlightThresholdLux = 7000;

  bool _isAnalysisVisible = false;

  void _toggleAnalysis() {
    // Anti-Pattern Avoidance: Simple state change logic is safe here
    setState(() {
      _isAnalysisVisible = !_isAnalysisVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadForecast('40.813238367880984,14.208889980642137', "Posillipo");
    _initLightSensor();

    _pageController.addListener(() {
      // Anti-Pattern Avoidance: Checks mounted status before setState in listener
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

  void _initLightSensor() {
    try {
      _lightSubscription = Light().lightSensorStream.listen((luxValue) {
        final isBright = luxValue > _sunlightThresholdLux;
        // Anti-Pattern Avoidance: Only call setState if the value changes
        if (isBright != _isSunlightModeActive) {
          if (mounted) {
            setState(() {
              _isSunlightModeActive = isBright;
            });
          }
        }
      }, onError: (error) {
        print("[Sunlight Mode] Sensor stream error: $error"); // Debug log
        _lightSubscription?.cancel();
      });
    } catch (e) {
      print(
          "[Sunlight Mode] Could not start sensor (likely unavailable): $e"); // Debug log
    }
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _pageController.dispose();
    _searchOverlayEntry?.remove();
    super.dispose();
  }

  void _loadForecast(String location, String name) {
    if (!mounted) return;
    setState(() {
      _currentLocationName = name;
      // Robust error handling with fallback logic for stale data
      _forecastFuture = _apiService.fetchForecastData(location).catchError((e) {
        if (e is NetworkErrorWithStaleDataException && mounted) {
          showStaleDataDialog(context).then((useStaleData) {
            if (useStaleData == true) {
              setState(() {
                // Re-assign Future to use cached data
                _forecastFuture = Future.value(
                    _apiService.parseForecastData(e.staleJsonData));
              });
            } else {
              setState(() {
                // Future fails if user rejects stale data
                _forecastFuture =
                    Future.error(Exception('Update rejected by user.'));
              });
            }
          });
        }
        // Re-throw if it's not the handled exception or if dialog wasn't shown
        throw e;
      });
    });
  }

  void _onGpsSearch() async {
    _removeSearchOverlay();
    if (!mounted) return;
    // Anti-Pattern Avoidance: Set loading state before heavy operation
    setState(() => _isLoadingGps = true);
    try {
      // Heavy operation on separate thread (handled internally by API service/Geolocator)
      final locationData = await _apiService.getCurrentGpsLocation();
      final coords = locationData['coords']!; // Nullable handled internally
      final name = locationData['name']!;
      _loadForecast(coords, name);
    } on LocationServicesDisabledException {
      if (!mounted) return;
      showLocationServicesDialog(context);
    } catch (e) {
      if (!mounted) return;
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll("Exception: ", "")),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      // Anti-Pattern Avoidance: Clear loading state in finally block
      if (mounted) {
        setState(() => _isLoadingGps = false);
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
    // Best Practice: Extracted widget creation to a separate method
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
    // Critical Constraint: No heavy logic in build() method.
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
                // Critical Constraint: Handle empty/null case
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
                    // 1. Background Image and Overlay
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        // Animated image for transition effect
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
                        // Sunlight mode dark overlay
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
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // PageView for swiping forecast
                        PageView.builder(
                          controller: _pageController,
                          // ListView.builder used for long list (Critical Constraint/Anti-Pattern Avoidance)
                          itemCount: forecasts.length,
                          onPageChanged: (index) {
                            if (mounted) {
                              // Anti-Pattern Avoidance
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
                            // Creates display list for WeeklyForecast (excluding current day)
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
                                  setState(() {
                                    _isHourlyForecastExpanded = isExpanded;
                                  });
                              },
                              isToday: isActuallyToday,
                              isSunlightModeActive: _isSunlightModeActive,
                              onAnalysisTap: _toggleAnalysis,
                            );
                          },
                        )
                      ],
                    ),
                    // 2. Blur Overlay for Analysis Card
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
                    // 3. Dismissible Overlay
                    if (_isAnalysisVisible)
                      GestureDetector(
                        onTap: _toggleAnalysis,
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 400),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    // 4. Analysis Card (with constrained height and vertical padding)
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
                              // Horizontal padding from the original context
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Padding(
                                // [PREMIUM PLUS] Adds vertical breathing room to the card
                                padding:
                                    const EdgeInsets.symmetric(vertical: 60.0),
                                child: ConstrainedBox(
                                  // Constrains the maximum height of the card
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context)
                                            .size
                                            .height *
                                        0.75, // Limits height to 75% of screen
                                  ),
                                  child: AnalystCard(
                                    key: ValueKey(
                                        "analysis_card_${_currentPageIndex}"), // Chiave dinamica
                                    // Passa le coordinate della giornata attualmente visualizzata
                                    lat: forecasts[_currentPageIndex]
                                            .hourlyData
                                            .isNotEmpty
                                        ? (forecasts[_currentPageIndex]
                                                .hourlyData[0]['latitude'] ??
                                            40.813)
                                        : 40.813,
                                    lon: forecasts[_currentPageIndex]
                                            .hourlyData
                                            .isNotEmpty
                                        ? (forecasts[_currentPageIndex]
                                                .hourlyData[0]['longitude'] ??
                                            14.208)
                                        : 14.208,
                                    onClose: _toggleAnalysis,
                                    // ECCO IL PASSAGGIO DEI DATI CHE RISOLVE L'ERRORE
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
      // Logic for AppBar transparency based on scroll offset
      final newOpacity = (_scrollController.offset / 80).clamp(0.0, 1.0);
      if (newOpacity != _appBarOpacity) {
        if (mounted) {
          // Anti-Pattern Avoidance: Checks mounted status
          setState(() {
            _appBarOpacity = newOpacity;
          });
        }
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
    // CustomScrollView used for complex scrolling effects (SliverAppBar)
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          // Glassmorphism effect for the pinned app bar
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
                // Applies shadows only in bright sunlight mode for better contrast
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
            // Uses SliverChildListDelegate for a fixed list of widgets (correct syntax)
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
                // Callback to update the parent state when header is tapped
                onHeaderTap: () =>
                    widget.onHourlyExpansionChanged(!widget.isHourlyExpanded),
                padding: const EdgeInsets.all(20.0),
                child: HourlyForecast(
                  // Logic to show today's forecast starting from the current hour
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
                // Passes the list of remaining days for the weekly view
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
