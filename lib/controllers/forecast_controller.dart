// lib/controllers/forecast_controller.dart

import 'package:flutter/material.dart';
import '../models/forecast_data.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class ForecastController with ChangeNotifier {
  final ApiService _apiService;
  final CacheService _cacheService;

  ForecastController({
    required ApiService apiService,
    required CacheService cacheService,
  })  : _apiService = apiService,
        _cacheService = cacheService;

  // --- STATO ---
  List<ForecastData>? _forecastData;
  String _errorMessage = '';
  bool _isLoading = true;
  String _currentLocationName = "Posillipo";

  // --- GETTERS PUBBLICI ---
  List<ForecastData>? get forecastData => _forecastData;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String get currentLocationName => _currentLocationName;

  // --- LOGICA DI BUSINESS ---

  /// Inizializza il caricamento dei dati con logica "Offline-First".
  Future<void> initializeForecast(String location, String name) async {
    _isLoading = true;
    _currentLocationName = name;
    _errorMessage = '';
    notifyListeners();

    final cachedData = await _cacheService.getValidForecast();
    if (cachedData != null) {
      _forecastData = cachedData;
      _isLoading = false;
      print("[ForecastController] Dati caricati dalla cache.");
      notifyListeners();
      return;
    }

    print("[ForecastController] Cache vuota/scaduta. Chiamo la rete.");
    await fetchAndLoadForecast(location, name);
  }

  /// Recupera, salva e carica i dati dalla rete.
  Future<void> fetchAndLoadForecast(String location, String name) async {
    _currentLocationName = name;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final String forecastJson = await _apiService.fetchForecastJson(location);
      await _cacheService.saveForecast(forecastJson);
      final List<ForecastData>? freshData =
          await _cacheService.getValidForecast();

      _forecastData = freshData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll("ApiException: ", "");
      _isLoading = false;
      print("[ForecastController] Errore di caricamento: $_errorMessage");
      notifyListeners();
    }
  }

  /// Gestisce la ricerca tramite GPS.
  Future<void> onGpsSearch() async {
    try {
      final locationData = await _apiService.getCurrentGpsLocation();
      await fetchAndLoadForecast(
          locationData['coords']!, locationData['name']!);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      // Potremmo voler mostrare una SnackBar qui, gestita dalla UI
      print("[ForecastController] Errore GPS: $_errorMessage");
    }
  }
}
