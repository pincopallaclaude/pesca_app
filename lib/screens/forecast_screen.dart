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
    _loadForecast('40.813238367880984,14.208944303204635', "Posillipo");
  }

  void _loadForecast(String location, String name) {
    if (!mounted) return;
    setState(() {
      _currentLocationName = name;
      // Il FutureBuilder ora gestirà autonomamente i casi di successo, caricamento ed errore.
      // La nostra logica personalizzata intercetta solo l'eccezione con dati obsoleti.
      _forecastFuture = _apiService.fetchForecastData(location).catchError((e) {
        if (e is NetworkErrorWithStaleDataException && mounted) {
          showStaleDataDialog(context).then((useStaleData) {
            if (useStaleData == true) {
              // Se l'utente accetta, aggiorniamo il future con i dati obsoleti.
              setState(() {
                // Chiamata al metodo PUBBLICO 'parseForecastData'.
                _forecastFuture =
                    Future.value(_apiService.parseForecastData(e.staleJsonData));
              });
            } else {
              // Altrimenti, propaghiamo l'errore al FutureBuilder.
              setState(() {
                _forecastFuture = Future.error(Exception('Aggiornamento rifiutato.'));
              });
            }
          });
        }
        // Rilancia l'eccezione per farla gestire dal FutureBuilder.
        throw e;
      });
    });
  }

  // NUOVA IMPLEMENTAZIONE della ricerca GPS
  void _onGpsSearch() async {
    _removeSearchOverlay();
    if (!mounted) return;

    setState(() { _isLoadingGps = true; });

    try {
      // Chiama il servizio per ottenere posizione e nome
      final locationData = await _apiService.getCurrentGpsLocation();
      final coords = locationData['coords']!;
      final name = locationData['name']!;
      
      // Carica le nuove previsioni
      _loadForecast(coords, name);

    } on LocationServicesDisabledException {
      // CASO SPECIFICO: i servizi GPS sono spenti. Mostra il dialogo personalizzato.
      if (!mounted) return;
      showLocationServicesDialog(context);

    } catch (e) {
      // CASO GENERICO: altri errori (permessi negati, rete, etc.). Mostra la SnackBar.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")), // Pulisce il messaggio
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      // Alla fine del processo, nascondi sempre l'indicatore
      if (mounted) {
        setState(() { _isLoadingGps = false; });
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
          ? Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white)))
          : FutureBuilder<List<ForecastData>>(
              future: _forecastFuture,
              builder: (context, snapshot) {
                // Durante il caricamento iniziale (o dopo un refresh), mostriamo uno sfondo nero
                if (!snapshot.hasData) {
                  return Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white)));
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Errore: ${snapshot.error}',
                          style: const TextStyle(
                              color: Colors.white, backgroundColor: Colors.black54),
                          textAlign: TextAlign.center));
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nessun dato.', style: TextStyle(color: Colors.white)));
                }

                final forecasts = snapshot.data!;
                // Il path dell'immagine viene determinato dalla logica nel modello dati del primo giorno
                final backgroundPath = forecasts[0].backgroundImagePath;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Sfondo Dinamico con animazione
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Image.asset(
                        backgroundPath,
                        key: ValueKey(backgroundPath), // Chiave per far scattare l'animazione
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    
                    // Gradiente per la leggibilità del testo
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
                    
                    // Contenuto principale dell'app
                    PageView.builder(
                      itemCount: forecasts.length,
                      itemBuilder: (context, index) {
                        return ForecastPage(
                            data: forecasts[index],
                            locationName: _currentLocationName,
                            onSearchTap: _toggleSearchPanel);
                      },
                    )
                  ],
                );
              },
            ),
    );
  }
}

// Widget per la singola pagina di previsione
class ForecastPage extends StatelessWidget {
  final ForecastData data;
  final String locationName;
  final VoidCallback onSearchTap;

  const ForecastPage(
      {required this.data,
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
          title: Text(locationName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 22)),
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
            MainHeroModule(data: data),
            const SizedBox(height: 20),
            GlassmorphismCard(
                title: "PREVISIONI NELLE PROSSIME ORE",
                child: HourlyForecast(hourlyData: data.hourlyData)),
            const SizedBox(height: 20),
            GlassmorphismCard(
                title: "PREVISIONI A 7 GIORNI",
                child: WeeklyForecast(weeklyData: data.weeklyData)),
          ])),
        ),
      ],
    );
  }
}