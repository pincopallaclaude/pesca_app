// lib/widgets/analysis_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/analysis_viewmodel.dart';
import 'analysis_skeleton_loader.dart';

class AnalysisView extends StatelessWidget {
  final VoidCallback onClose;

  const AnalysisView({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.60;

    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (viewModel.currentState) {
            AnalysisState.loading => const AnalysisSkeletonLoader(),
            AnalysisState.success =>
              _buildPremiumGlass(context, viewModel, maxH),
            AnalysisState.error => _buildErrorState(context, viewModel),
          },
        );
      },
    );
  }

  Widget _buildPremiumGlass(
      BuildContext context, AnalysisViewModel viewModel, double maxH) {
    return Container(
      width:
          double.infinity, // Risolve la issue delle frecce rosse (espansione)
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A)
            .withOpacity(0.95), // Blu scuro profondo (stile "PRIMA")
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTransparentHeader(viewModel),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.cyanAccent.withOpacity(0.15),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH - 80),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: _buildMarkdownContent(context, viewModel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransparentHeader(AnalysisViewModel viewModel) {
    return Container(
      color: Colors.white.withOpacity(0.02),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'INSIGHT DI PESCA',
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                _buildNanoBadge(viewModel),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white60, size: 22),
            style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ],
      ),
    );
  }

  Widget _buildNanoBadge(AnalysisViewModel vm) {
    final model = (vm.cachedMetadata?['modelUsed'] as String?) ?? 'AI V2';
    String display = model.contains('flash') ? 'Gemini 2.5' : 'RAG Powered';
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Text('$display // Live Analysis',
          style: GoogleFonts.robotoMono(
              fontSize: 10, color: Colors.cyanAccent.withOpacity(0.7))),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, AnalysisViewModel vm) {
    final h1Style = GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE0F7FA),
        height: 2.0);
    final h2Style = GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
        height: 1.8);
    final bodyStyle = GoogleFonts.inter(
        fontSize: 14, height: 1.6, color: Colors.white.withOpacity(0.85));
    final numberStyle = GoogleFonts.robotoMono(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFD700));

    return MarkdownBody(
      data: vm.analysisText ?? "",
      styleSheet: MarkdownStyleSheet(
        h1: h1Style,
        h2: h2Style,
        p: bodyStyle,
        strong: numberStyle,
        listBullet: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
        listIndent: 12.0,
        blockSpacing: 12.0,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AnalysisViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
          const SizedBox(height: 12),
          Text(vm.errorText,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
