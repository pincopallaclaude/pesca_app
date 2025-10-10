// lib/widgets/analyst_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import '../services/api_service.dart';
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

// Implementazione custom per la Linea Orizzontale (HR) - UNICO BUILDER MANTENUTO
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

  const AnalystCard({
    super.key,
    required this.lat,
    required this.lon,
    required this.onClose,
  });

  @override
  State<AnalystCard> createState() => _AnalystCardState();
}

class _AnalystCardState extends State<AnalystCard> {
  final ApiService _apiService = ApiService();
  AnalysisState _currentState = AnalysisState.loading;
  String? _analysisText;
  String _errorText = '';

  // Mappa dei builder contenente solo 'hr' (risolto errore _inlines.isEmpty)
  late final Map<String, MarkdownElementBuilder> _builders = {
    'hr': HorizontalRuleBuilder(),
  };

  // Definisce lo style sheet: rimossi parametri obsoleti (risolto errore 'li'/'marginBottom')
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
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    if (!mounted) return;
    setState(() {
      _currentState = AnalysisState.loading;
    });

    // *************************************************************************
    // CORREZIONE CRITICA: Costruiamo la stringa di coordinate (lat,lon)
    // *************************************************************************
    final String locationCoords = '${widget.lat},${widget.lon}';

    // Query fissa per l'analisi RAG
    const String analysisQuery =
        'What are the best fishing conditions for today?';

    print(
        '[AnalystCard DEBUG] Inizio fetchAnalysis con coords: $locationCoords');

    try {
      final result = await _apiService.fetchAnalysis(
          locationCoords, analysisQuery); // USIAMO LA STRINGA DI COORDINATE

      if (!mounted) return;
      setState(() {
        _analysisText = result;
        _currentState = AnalysisState.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      print('[AnalystCard Log] API Exception: ${e.message}');
      setState(() {
        _errorText = e.message;
        _currentState = AnalysisState.error;
      });
    } catch (e) {
      if (!mounted) return;
      print('[AnalystCard Log] Generic Error: $e');
      setState(() {
        _errorText = 'A generic error occurred: $e';
        _currentState = AnalysisState.error;
      });
    }
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_currentState) {
            AnalysisState.loading =>
              _buildLoadingIndicator(key: const ValueKey('loading')),
            AnalysisState.success =>
              _buildSuccessCard(key: const ValueKey('success')),
            AnalysisState.error =>
              _buildErrorCard(key: const ValueKey('error')),
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: Colors.cyanAccent),
        const SizedBox(height: 16),
        Text(
          "L'IA sta analizzando i dati...",
          style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccessCard({Key? key}) {
    final headerStyle = GoogleFonts.lato(
      color: const Color(0xFFFFD700).withOpacity(0.9),
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );

    return AnimationLimiter(
      key: key,
      child: Column(
        // mainAxisSize.min è essenziale, ma richiede un'altezza definita per il contenuto scrollabile.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 450),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Staggered child 1: Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: headerStyle.color, size: 18),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INSIGHT DI PESCA', style: headerStyle),
                    Text('RAG-Powered',
                        style: GoogleFonts.lato(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 1.0)),
                  ],
                ),
                const Spacer(),
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

            // Staggered child 3: Main content - CORREZIONE FINALE LAYOUT
            // ConstrainedBox risolve l'errore Flexible/Expanded forzando un'altezza massima.
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
            onPressed: _fetchAnalysis,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
            label: const Text('Riprova', style: TextStyle(color: Colors.white)))
      ],
    );
  }
}
