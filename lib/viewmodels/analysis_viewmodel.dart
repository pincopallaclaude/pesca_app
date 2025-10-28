// lib/viewmodels/analysis_viewmodel.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../models/forecast_data.dart';

enum AnalysisState { loading, success, error }

class AnalysisViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  AnalysisState _currentState = AnalysisState.loading;
  AnalysisState get currentState => _currentState;

  String? _analysisText;
  String? get analysisText => _analysisText;

  String _errorText = '';
  String get errorText => _errorText;

  Map<String, dynamic>? _cachedMetadata;
  Map<String, dynamic>? get cachedMetadata => _cachedMetadata;

  final double _lat;
  final double _lon;

  AnalysisViewModel(this._lat, this._lon) {
    _initializeAnalysis();
  }

  /// Orchestra il caricamento dell'analisi in 3 fasi.
  Future<void> _initializeAnalysis() async {
    // 1. Reset dello stato
    _currentState = AnalysisState.loading;
    _errorText = '';
    _cachedMetadata = null;
    notifyListeners();

    try {
      // 2. Prova cache locale (Hive)
      final cachedData = await _cacheService.getValidAnalysis(_lat, _lon);
      if (cachedData != null) {
        print('[ViewModel] Cache HIT (Local)');
        _setData(cachedData['analysis'], cachedData['metadata']);
        return;
      }

      // 3. Prova cache backend
      print('[ViewModel] Cache MISS (Local). Checking Backend...');
      final backendCache = await _apiService.getAnalysisFromCache(_lat, _lon);
      if (backendCache['status'] == 'ready') {
        print('[ViewModel] Cache HIT (Backend)');
        final analysis = backendCache['analysis'] as String;
        final metadata = backendCache['metadata'] as Map<String, dynamic>?;
        await _cacheService.saveAnalysis(_lat, _lon, analysis,
            metadata: metadata);
        _setData(analysis, metadata);
        return;
      }

      // 4. Fallback: genera on-demand
      print('[ViewModel] Cache MISS (Backend). Generating on-demand...');
      final result = await _apiService.generateAnalysisFallback(_lat, _lon);
      final analysis = result['analysis'] as String;
      final metadata = result['metadata'] as Map<String, dynamic>?;
      await _cacheService.saveAnalysis(_lat, _lon, analysis,
          metadata: metadata);
      _setData(analysis, metadata);
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Errore inatteso: ${e.toString()}');
    }
  }

  void _setData(String analysis, Map<String, dynamic>? metadata) {
    _analysisText = analysis;
    _cachedMetadata = metadata;
    _currentState = AnalysisState.success;
    notifyListeners();
  }

  void _setError(String message) {
    _errorText = message;
    _currentState = AnalysisState.error;
    notifyListeners();
  }

  // Permette alla UI di richiedere un nuovo tentativo
  void retry() {
    _initializeAnalysis();
  }
}
