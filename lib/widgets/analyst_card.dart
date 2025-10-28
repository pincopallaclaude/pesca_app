// lib/widgets/analyst_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../models/forecast_data.dart';
import 'analysis_skeleton_loader.dart';
import 'glassmorphism_card.dart';

// -----------------------------------------------------------------------------
// STILI & BUILDERS
// -----------------------------------------------------------------------------

final Color baseTextColor = const Color(0xFFEAEAEA);
final TextStyle baseStyle =
    GoogleFonts.lora(color: baseTextColor, fontSize: 16, height: 1.6);
final TextStyle strongStyle = GoogleFonts.lato(
    fontWeight: FontWeight.w900, color: const Color(0xFFFFC107)); // Amber
final TextStyle warningStyle = GoogleFonts.lato(
    fontWeight: FontWeight.w900, color: const Color(0xFFEF6C00)); // Deep Coral
final TextStyle h3Style = GoogleFonts.lato(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.4);

// Implementazione custom per la Linea Orizzontale (HR)
class HorizontalRuleBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return const Divider(color: Colors.white38, height: 32, thickness: 1);
  }
}

// -----------------------------------------------------------------------------
// ANALYST CARD (WIDGET PRINCIPALE)
// -----------------------------------------------------------------------------

enum AnalysisState { loading, success, error }

class AnalystCard extends StatefulWidget {
  final double lat;
  final double lon;
  final VoidCallback onClose;
  final List<ForecastData> forecastData;

  const AnalystCard({
    super.key,
    required this.lat,
    required this.lon,
    required this.onClose,
    required this.forecastData,
  });

  @override
  State<AnalystCard> createState() => _AnalystCardState();
}

class _AnalystCardState extends State<AnalystCard> {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  AnalysisState _currentState = AnalysisState.loading;
  String? _analysisText;
  String _errorText = '';
  Map<String, dynamic>? _cachedMetadata; // Variabile di stato per i metadati

  // Mappa dei builder contenente solo 'hr'
  late final Map<String, MarkdownElementBuilder> _builders = {
    'hr': HorizontalRuleBuilder(),
  };

  // Definisce lo style sheet
  late final MarkdownStyleSheet _styleSheet =
      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
    h3: h3Style,
    strong: strongStyle,
    em: baseStyle.copyWith(fontStyle: FontStyle.italic),
    del: warningStyle.copyWith(decoration: TextDecoration.none),

    // Stile base per il paragrafo
    p: baseStyle.copyWith(height: 1.6),

    // Stile per il list item
    listIndent: 20,
    listBullet: strongStyle, // Stile standard per il bullet (Amber)
    listBulletPadding: const EdgeInsets.only(right: 8.0, top: 4.0),

    horizontalRuleDecoration: const BoxDecoration(),
  );

  @override
  void initState() {
    super.initState();
    _initializeAnalysis(); // CHIAMATA ALL'ORCHESTRATORE
  }

  /// Orchestra il caricamento dell'analisi in 3 fasi: cache locale, cache backend, fallback.
  Future<void> _initializeAnalysis() async {
    if (!mounted) return;
    setState(() {
      _currentState = AnalysisState.loading;
      _errorText = '';
      _cachedMetadata = null;
    });

    try {
      // 1. Prova a caricare dalla cache locale (Hive)
      final cachedData =
          await _cacheService.getValidAnalysis(widget.lat, widget.lon);
      if (cachedData != null && mounted) {
        print('[AnalystCard] Cache HIT (Local)');
        setState(() {
          _analysisText = cachedData['analysis'] as String;
          _cachedMetadata = cachedData['metadata'] as Map<String, dynamic>?;
          _currentState = AnalysisState.success;
        });
        return;
      }

      // 2. Prova cache backend (API service)
      print('[AnalystCard] Cache MISS (Local). Checking Backend...');
      final backendCache =
          await _apiService.getAnalysisFromCache(widget.lat, widget.lon);
      if (backendCache['status'] == 'ready' && mounted) {
        print('[AnalystCard] Cache HIT (Backend)');
        final analysis = backendCache['analysis'] as String;
        final metadata = backendCache['metadata'] as Map<String, dynamic>?;

        // Salva il risultato nella cache locale
        await _cacheService.saveAnalysis(widget.lat, widget.lon, analysis,
            metadata: metadata);

        setState(() {
          _analysisText = analysis;
          _cachedMetadata = metadata;
          _currentState = AnalysisState.success;
        });
        return;
      }

      // 3. Fallback: genera on-demand
      print('[AnalystCard] Cache MISS (Backend). Generating on-demand...');
      final result =
          await _apiService.generateAnalysisFallback(widget.lat, widget.lon);

      if (mounted) {
        final analysis = result['analysis'] as String;
        final metadata = result['metadata'] as Map<String, dynamic>?;

        // Salva il risultato fresco nella cache locale
        await _cacheService.saveAnalysis(widget.lat, widget.lon, analysis,
            metadata: metadata);

        setState(() {
          _analysisText = analysis;
          _cachedMetadata = metadata;
          _currentState = AnalysisState.success;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      print('[AnalystCard] API Exception: ${e.message}');
      setState(() {
        _errorText = e.message;
        _currentState = AnalysisState.error;
      });
    } catch (e) {
      if (!mounted) return;
      print('[AnalystCard] Generic Error: $e');
      setState(() {
        _errorText = 'Errore inatteso: ${e.toString()}';
        _currentState = AnalysisState.error;
      });
    }
  }

  /// Costruisce il badge dinamico del modello LLM utilizzato.
  Widget _buildModelBadge() {
    String modelDisplay = 'RAG-Powered';
    if (_cachedMetadata != null && _cachedMetadata!['modelUsed'] != null) {
      final model = _cachedMetadata!['modelUsed'] as String;
      // Normalizzazione del nome del modello
      if (model.contains('gemini')) {
        modelDisplay = 'RAG | Gemini';
      } else if (model.contains('claude')) {
        modelDisplay = 'RAG | Claude';
      } else if (model.contains('mistral')) {
        modelDisplay = 'RAG | Mistral';
      } else {
        // Fallback per modelli generici o nuovi
        modelDisplay = 'RAG | ${model.split('-')[0]}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Text(
        modelDisplay,
        style: GoogleFonts.robotoMono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildMarkdownContent() {
    if (_analysisText == null || _analysisText!.isEmpty) {
      return const Text('Nessuna analisi disponibile.',
          style: TextStyle(color: Colors.white70));
    }

    // Usa DefaultTextStyle per tentare di forzare la giustificazione
    return DefaultTextStyle.merge(
      textAlign: TextAlign.justify,
      child: MarkdownBody(
        data: _analysisText!,
        styleSheet: _styleSheet,
        builders: _builders,
        shrinkWrap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: switch (_currentState) {
          AnalysisState.loading =>
            // ASSICURATI CHE QUESTA SIA LA RIGA PRESENTE
            const AnalysisSkeletonLoader(key: ValueKey('loading')),
          AnalysisState.success =>
            _buildSuccessCard(key: const ValueKey('success')),
          AnalysisState.error => _buildErrorCard(key: const ValueKey('error')),
        },
      ),
    );
  }

  Widget _buildSuccessCard({Key? key}) {
    // Rimuoviamo la definizione di headerStyle non più necessaria per il testo
    // principale, ma usiamo il colore per l'icona.
    final headerIconColor = const Color(0xFFFFD700); // Gold

    return AnimationLimiter(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 450),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Staggered child 1: Header (Struttura rivista)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icona e Titolo (con il nuovo stile)
                Icon(Icons.auto_awesome, color: headerIconColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  'INSIGHT DI PESCA',
                  style: GoogleFonts.robotoCondensed(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.white),
                ),
                const SizedBox(width: 10),
                _buildModelBadge(), // Badge Dinamico
                const Spacer(),

                // Pulsante di chiusura (preservato)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(50),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            // Staggered child 2: Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(color: Colors.white24, height: 1, thickness: 1),
            ),

            // Staggered child 3: Main content
            ConstrainedBox(
              // Altezza massima del contenuto (adatta questo valore se necessario)
              constraints: const BoxConstraints(
                maxHeight: 400.0,
              ),
              child: SingleChildScrollView(
                child: _buildMarkdownContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 8),
                Text('Errore',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          ],
        ),
        const SizedBox(height: 12),
        Text(_errorText,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: _initializeAnalysis,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
            label: const Text('Riprova', style: TextStyle(color: Colors.white)))
      ],
    );
  }
}
