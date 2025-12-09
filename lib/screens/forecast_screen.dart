// /lib/screens/forecast_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:light/light.dart';

import '../viewmodels/forecast_viewmodel.dart';
import '../models/forecast_data.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../widgets/analyst_card.dart';
import '../widgets/search_overlay.dart';
import '../widgets/forecast_view.dart';
import '../widgets/location_services_dialog.dart';
import 'mission_control/mission_control_screen.dart';
import '../widgets/premium_drawer/premium_drawer.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});
  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with TickerProviderStateMixin {
  late final ForecastController _controller;
  final PageController _pageController = PageController();
  late AnimationController _drawerAnimationController;
  late AnimationController _particleController;

  int _currentPageIndex = 0;
  bool _isHourlyForecastExpanded = false;
  bool _isAnalysisVisible = false;
  OverlayEntry? _searchOverlayEntry;
  bool _isLoadingGps = false;

  StreamSubscription<int>? _lightSubscription;
  bool _isSunlightModeActive = false;
  static const int _sunlightThresholdLux = 7000;

  @override
  void initState() {
    super.initState();
    _controller = ForecastController(
      apiService: ApiService(),
      cacheService: CacheService(),
    )..initializeForecast('40.813,14.208', "Posillipo");

    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initLightSensor();
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _pageController.dispose();
    _searchOverlayEntry?.remove();
    _controller.dispose();
    _drawerAnimationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initLightSensor() {
    try {
      _lightSubscription = Light().lightSensorStream.listen((luxValue) {
        if (mounted) {
          setState(
              () => _isSunlightModeActive = luxValue > _sunlightThresholdLux);
        }
      });
    } catch (e) {
      print("[Sunlight Sensor] Errore: $e");
    }
  }

  void _toggleSearchPanel() {
    if (_searchOverlayEntry == null) {
      _searchOverlayEntry = OverlayEntry(
        builder: (context) => SearchOverlay(
          onClose: _toggleSearchPanel,
          onLocationSelected: (location, name) {
            _removeSearchOverlay();
            _controller.fetchAndLoadForecast(location, name);
          },
          onGpsSearch: _onGpsSearch,
        ),
      );
      Overlay.of(context).insert(_searchOverlayEntry!);
    } else {
      _removeSearchOverlay();
    }
  }

  void _removeSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  void _toggleAnalysis() {
    HapticFeedback.mediumImpact();
    setState(() => _isAnalysisVisible = !_isAnalysisVisible);
  }

  Future<void> _onGpsSearch() async {
    _removeSearchOverlay();
    if (!mounted) return;
    setState(() => _isLoadingGps = true);
    try {
      await _controller.onGpsSearch();
    } on LocationServicesDisabledException {
      if (mounted) showLocationServicesDialog(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
    if (mounted) setState(() => _isLoadingGps = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: PremiumDrawer(particleController: _particleController),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ForecastView(
                controller: _controller,
                pageController: _pageController,
                currentPageIndex: _currentPageIndex,
                isHourlyForecastExpanded: _isHourlyForecastExpanded,
                isAnalysisVisible: _isAnalysisVisible,
                isSunlightModeActive: _isSunlightModeActive,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                    _isHourlyForecastExpanded = false;
                  });
                },
                onHourlyExpansionChanged: (isExpanded) {
                  setState(() => _isHourlyForecastExpanded = isExpanded);
                },
                onAnalysisTap: _toggleAnalysis,
                onSearchTap: _toggleSearchPanel,
              );
            },
          ),
          _buildOverlays(),
          if (_isLoadingGps)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlays() {
    final forecasts = _controller.forecastData;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isAnalysisVisible
              ? BackdropFilter(
                  key: const ValueKey('blur'),
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                )
              : const SizedBox.shrink(key: ValueKey('no-blur')),
        ),
        if (_isAnalysisVisible)
          GestureDetector(
            onTap: _toggleAnalysis,
            child: Container(color: Colors.transparent),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            );
          },
          child: _isAnalysisVisible && forecasts != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 60.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: AnalystCard(
                      key: ValueKey("analysis_card_$_currentPageIndex"),
                      lat: 40.813,
                      lon: 14.208,
                      onClose: _toggleAnalysis,
                      forecastData: forecasts,
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey("empty_card")),
        ),
      ],
    );
  }
}
