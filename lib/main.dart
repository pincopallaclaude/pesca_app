// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'screens/forecast_screen.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';

// -----------------------------------------------------------------------------
// LOGICA DI BACKGROUND
// -----------------------------------------------------------------------------

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("[Workmanager] Task in background avviato...");

    // Inizializzazione dei servizi in un Isolate separato
    // È FONDAMENTALE re-inizializzare tutto ciò che serve al task.
    await Hive.initFlutter();
    await Hive.openBox('forecastCache');
    await Hive.openBox('analysisCache');

    final apiService = ApiService();
    final cacheService = CacheService();

    try {
      // NOTA: Per questa prima implementazione, il task aggiorna una
      // località predefinita. Una versione futura potrebbe salvare l'ultima
      // località cercata dall'utente e aggiornare quella.
      const defaultLocation = '40.813,14.208'; // Posillipo

      print(
          '[Workmanager] Eseguo il fetch in background per: $defaultLocation');
      final forecastJson = await apiService.fetchForecastJson(defaultLocation);
      await cacheService.saveForecast(forecastJson);

      print('[Workmanager] Aggiornamento previsioni completato con successo.');
      return Future.value(true);
    } catch (e) {
      print('[Workmanager] ERRORE durante il task in background: $e');
      return Future.value(false);
    }
  });
}

// -----------------------------------------------------------------------------
// APPLICAZIONE PRINCIPALE
// -----------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Hive
  await Hive.initFlutter();
  await Hive.openBox('forecastCache');
  await Hive.openBox('analysisCache');

  // Inizializza e pianifica il Workmanager
  await Workmanager().initialize(callbackDispatcher,
      isInDebugMode: false); // false per evitare log eccessivi in produzione
  await Workmanager().registerPeriodicTask(
    "pesca-app-periodic-update", // Nome univoco del task
    "aggiornamentoDatiPeriodico", // Nome dell'operazione
    frequency: const Duration(hours: 6),
    //initialDelay: const Duration(minutes: 15), // Attende 15 min dopo il primo avvio
    initialDelay: const Duration(seconds: 20), // Esegui dopo 20 secondi
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow:
          true, // Esegui solo se la batteria non è quasi scarica
    ),

    // Strategia per gestire i conflitti: se un task è già pianificato, mantieni quello esistente.
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const PescaApp());
}

class PescaApp extends StatelessWidget {
  const PescaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Previsioni Pesca',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D121B),
        fontFamily: 'Roboto',
      ),
      home: const ForecastScreen(),
    );
  }
}
