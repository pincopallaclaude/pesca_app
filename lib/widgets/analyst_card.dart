// lib/widgets/analyst_card.dart

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'glassmorphism_card.dart';

// Enum remains unchanged
enum AnalysisState { loading, success, error }

class AnalystCard extends StatefulWidget {
  final double lat;
  final double lon;
  final VoidCallback onClose; // Required parameter

  const AnalystCard({
    super.key,
    required this.lat,
    required this.lon,
    required this.onClose, // Required parameter
  });

  @override
  State<AnalystCard> createState() => _AnalystCardState();
}

// --- NUVO CODICE DA INCOLLARE (IN SOSTITUZIONE DELL'INTERA CLASSE '_AnalystCardState') ---
class _AnalystCardState extends State<AnalystCard> {
  final ApiService _apiService = ApiService();
  AnalysisState _currentState = AnalysisState.loading;
  String? _analysisText;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    // unchanged
    if (!mounted) return;
    setState(() {
      _currentState = AnalysisState.loading;
    });
    try {
      final result = await _apiService.getAnalysis(widget.lat, widget.lon);
      if (!mounted) return;
      setState(() {
        _analysisText = result;
        _currentState = AnalysisState.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _currentState = AnalysisState.error;
      });
    }
  }

  /// Helper function to parse the styled text using RichText and RegExp,
  /// replacing **bold**, *italic*, and ##warning## tags with styled TextSpans.
  Widget _buildStyledText(String? text) {
    if (text == null) return const SizedBox.shrink();

    final List<TextSpan> spans = [];
    // Regex matches **bold**, *italic*, or ##warning## tags
    final RegExp aullExp = RegExp(r'(\*\*.*?\*\*|\*.*?\*|##.*?##)');

    text.splitMapJoin(
      aullExp,
      onMatch: (Match match) {
        String matchText = match[0]!;
        if (matchText.startsWith('**')) {
          // **Bold** style
          spans.add(TextSpan(
            text: matchText.replaceAll('**', ''),
            style: GoogleFonts.lora(
                fontWeight: FontWeight.bold,
                color: Colors.cyan.shade200,
                fontSize: 16),
          ));
        } else if (matchText.startsWith('*')) {
          // *Italic* style
          spans.add(TextSpan(
            text: matchText.replaceAll('*', ''),
            style: GoogleFonts.lora(
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.9),
                fontSize: 16),
          ));
        } else if (matchText.startsWith('##')) {
          // ##Warning## style
          spans.add(TextSpan(
            text: matchText.replaceAll('##', ''),
            style: GoogleFonts.lora(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade300,
                fontSize: 16),
          ));
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        // Plain text style
        spans.add(TextSpan(text: nonMatch));
        return '';
      },
    );

    return RichText(
      textAlign: TextAlign.justify, // Premium plus: Justified text alignment
      text: TextSpan(
        style: GoogleFonts.lora(
          // Default base style
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The main structure remains the same
    return GlassmorphismCard(
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16.0), // Match GlassmorphismCard's radius
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // The main structure remains the same
    // Use AnimatedSwitcher for a smooth transition between loading/success/error
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_currentState) {
          AnalysisState.loading =>
            _buildLoadingIndicator(key: const ValueKey('loading')),
          AnalysisState.success =>
            _buildSuccessCard(key: const ValueKey('success')),
          AnalysisState.error => _buildErrorCard(key: const ValueKey('error')),
        });
  }

  Widget _buildLoadingIndicator({Key? key}) {
    // unchanged
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(height: 20),
        CircularProgressIndicator(color: Colors.cyanAccent),
        SizedBox(height: 16),
        Text("L'IA sta analizzando i dati...",
            style: TextStyle(color: Colors.white70)),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccessCard({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min, // Essential to respect children's size.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0,
              0), // Removed bottom padding to attach divider cleanly
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insight di Pesca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI-Powered',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                    child: Icon(Icons.close, color: Colors.white70, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Divider
        const Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 20.0), // Divider is inset like the text.
          child: Divider(color: Colors.white24, height: 24),
        ),

        // Body: Replaced AnimatedTextKit/Markdown with custom RichText parser
        Padding(
          // Here we only need horizontal padding, and a smaller bottom one.
          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
          child: _buildStyledText(_analysisText),
        ),
      ],
    );
  }

  Widget _buildErrorCard({Key? key}) {
    final headerStyle = GoogleFonts.lora(
      color: Colors.cyanAccent.withOpacity(0.9),
      fontSize: 14, // Slightly larger to give it more presence
      fontWeight: FontWeight.w700, // Bolder for a clearer title hierarchy
      letterSpacing: 0.5,
    );
    // unchanged
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline,
                color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 8),
            Text('Errore',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
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
