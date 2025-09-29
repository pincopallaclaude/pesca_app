// lib/screens/forecast_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';

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
  bool _isLoadingGps = false; // Nuovo stato per il caricamento GPS
  final ApiService _apiService = ApiService(); // Istanza del servizio

  @override
  void initState() {
    super.initState();
    _loadForecast('40.813238367880984,14.208889980642137', "Posillipo");
  }

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
                _forecastFuture =
                    Future.error(Exception('Aggiornamento rifiutato.'));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ),
      );
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
                      child: Text('Errore: ${snapshot.error}',
                          style: const TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.black54),
                          textAlign: TextAlign.center));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nessun dato.',
                          style: TextStyle(color: Colors.white)));
                }

                final forecasts = snapshot.data!;
                final backgroundPath = forecasts[0].backgroundImagePath;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Image.asset(
                        backgroundPath,
                        key: ValueKey(backgroundPath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.black.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.4, 0.9],
                        ),
                      ),
                    ),

                    // **CORREZIONE LOGICA PAGEVIEW**
                    // Ora il PageView passa alla ForecastPage sia il dato del giorno
                    // corrente sia la lista completa per le previsioni settimanali.
                    PageView.builder(
                      itemCount: forecasts.length,
                      itemBuilder: (context, index) {
                        return ForecastPage(
                          currentDayData:
                              forecasts[index], // Dati del giorno corrente
                          allForecasts:
                              forecasts, // Tutta la lista di previsioni
                          locationName: _currentLocationName,
                          onSearchTap: _toggleSearchPanel,
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

class ForecastPage extends StatelessWidget {
  // **CORREZIONE DEI PARAMETRI**
  final ForecastData currentDayData;
  final List<ForecastData> allForecasts; // Lista completa dei dati
  final String locationName;
  final VoidCallback onSearchTap;

  const ForecastPage(
      {required this.currentDayData,
      required this.allForecasts,
      required this.locationName,
      required this.onSearchTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.1)))),
          elevation: 0,
          pinned: true,
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
          title: Text(locationName,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 22)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: onSearchTap,
              ),
            )
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            // Il modulo principale usa i dati del giorno corrente
            MainHeroModule(data: currentDayData),
            const SizedBox(height: 20),
            GlassmorphismCard(
                title: "PREVISIONI NELLE PROSSIME ORE",
                child: HourlyForecast(
                    hourlyData: currentDayData.hourlyForecastForDisplay)),
            const SizedBox(height: 20),

            // **CORREZIONE CHIAMATA WEEKLY FORECAST**
            // Il widget WeeklyForecast ora riceve la lista completa e gestirà
            // al suo interno la logica per mostrare i giorni corretti.
            GlassmorphismCard(
              title: "PREVISIONI A 7 GIORNI",
              child: WeeklyForecast(forecastData: allForecasts),
            ),
          ])),
        ),
      ],
    );
  }
}

// --- FINE NUOVO CODICE ---
