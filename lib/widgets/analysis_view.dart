// lib/widgets/analysis_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import '../viewmodels/analysis_viewmodel.dart';
import 'analysis_skeleton_loader.dart';

// Sposta stili e builder qui, perché sono legati alla View
final TextStyle baseStyle =
    GoogleFonts.lora(color: const Color(0xFFEAEAEA), fontSize: 16, height: 1.6);
final TextStyle strongStyle = GoogleFonts.lato(
    fontWeight: FontWeight.w900, color: const Color(0xFFFFC107));
final TextStyle h3Style = GoogleFonts.lato(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.4);

class HorizontalRuleBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return const Divider(color: Colors.white38, height: 32, thickness: 1);
  }
}

class AnalysisView extends StatelessWidget {
  final VoidCallback onClose;

  const AnalysisView({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    // Usa Consumer per ascoltare i cambiamenti del ViewModel
    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: switch (viewModel.currentState) {
            AnalysisState.loading =>
              const AnalysisSkeletonLoader(key: ValueKey('loading')),
            AnalysisState.success => _buildSuccessCard(context, viewModel,
                key: const ValueKey('success')),
            AnalysisState.error =>
              _buildErrorCard(context, viewModel, key: const ValueKey('error')),
          },
        );
      },
    );
  }

  Widget _buildSuccessCard(BuildContext context, AnalysisViewModel viewModel,
      {Key? key}) {
    final headerIconColor = const Color(0xFFFFD700);

    return AnimationLimiter(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 450),
          childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: headerIconColor, size: 18),
                        const SizedBox(width: 6),
                        Text('INSIGHT DI PESCA',
                            style: GoogleFonts.robotoCondensed(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildModelBadge(viewModel),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(50),
                      child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close,
                              color: Colors.white70, size: 20))),
                ),
              ],
            ),
            // Divider
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(color: Colors.white24, height: 1, thickness: 1)),
            // Contenuto Markdown
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400.0),
              child: SingleChildScrollView(
                  child: _buildMarkdownContent(context, viewModel)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, AnalysisViewModel viewModel,
      {Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Icon(Icons.error_outline,
                  color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              Text('Errore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold))
            ]),
            IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints())
          ],
        ),
        const SizedBox(height: 12),
        Text(viewModel.errorText,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: viewModel.retry,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
            label: const Text('Riprova', style: TextStyle(color: Colors.white)))
      ],
    );
  }

  Widget _buildModelBadge(AnalysisViewModel viewModel) {
    String modelDisplay = 'RAG Powered';
    final metadata = viewModel.cachedMetadata;
    if (metadata != null && metadata['modelUsed'] != null) {
      final model = metadata['modelUsed'] as String;
      String formattedModelName;
      if (model.contains('gemini-2.5-flash'))
        formattedModelName = 'Gemini 1.5 Flash';
      else if (model.contains('claude'))
        formattedModelName = 'Claude 3 Sonnet';
      else if (model.contains('mistral'))
        formattedModelName = 'Mistral 7B';
      else
        formattedModelName = model;
      modelDisplay = 'RAG Powered | $formattedModelName';
    }
    return Text(modelDisplay,
        style: GoogleFonts.robotoMono(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
            letterSpacing: 0.5));
  }

  Widget _buildMarkdownContent(
      BuildContext context, AnalysisViewModel viewModel) {
    if (viewModel.analysisText == null || viewModel.analysisText!.isEmpty) {
      return const Text('Nessuna analisi disponibile.',
          style: TextStyle(color: Colors.white70));
    }
    return DefaultTextStyle.merge(
      textAlign: TextAlign.justify,
      child: MarkdownBody(
        data: viewModel.analysisText!,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
            .copyWith(h3: h3Style, strong: strongStyle, p: baseStyle),
        builders: {'hr': HorizontalRuleBuilder()},
        shrinkWrap: true,
      ),
    );
  }
}
