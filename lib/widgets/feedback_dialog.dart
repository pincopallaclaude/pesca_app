// /widgets/feedback_dialog.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Dialog per raccogliere feedback utente
class FeedbackDialog extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> location;
  final Map<String, dynamic> weatherData;
  final double pescaScore;
  final String aiAnalysis;

  const FeedbackDialog({
    Key? key,
    required this.sessionId,
    required this.location,
    required this.weatherData,
    required this.pescaScore,
    required this.aiAnalysis,
  }) : super(key: key);

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _rating = 3;
  String _action = 'went_fishing';
  String _outcome = 'moderate';
  String? _feedbackReason; // Motivo specifico per feedback negativo
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);

    try {
      final apiService = ApiService();

      // Estraiamo lat/lon dall'oggetto location (che è Map<String, double>?)
      final lat = widget.location['lat'] as double?;
      final lon = widget.location['lon'] as double?;

      await apiService.submitFeedback({
        'sessionId':
            widget.sessionId, // Assicurati che questo sia un UUID valido!

        // APPATTIMENTO LOCATION (come vuole Zod)
        'location_lat': lat ?? 0.0,
        'location_lon': lon ?? 0.0,
        'location_name': 'Unknown', // O estrai se disponibile

        // RINOMINA DATI METEO
        'weather_json':
            widget.weatherData, // Rename weatherData -> weather_json

        'pescaScorePredicted': widget.pescaScore,
        'aiAnalysis': widget.aiAnalysis,

        'user_feedback': _rating,
        'userAction': _action,
        'outcome': _outcome,

        // GESTIONE REASON (evita null)
        if (_feedbackReason != null) 'feedback_reason': _feedbackReason,
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grazie per il feedback! 🎣'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Come è andata? 🎣'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Il tuo feedback ci aiuta a migliorare le previsioni!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Rating
            const Text('Quanto è stata accurata la previsione?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),

            if (_rating < 3) ...[
              const SizedBox(height: 20),
              const Text(
                'Cosa non ha funzionato? 🤔',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _feedbackReason,
                    hint: const Text('Seleziona un motivo...'),
                    items: [
                      'Condizioni meteo diverse dal previsto',
                      'Mare/Vento diversi dal previsto',
                      'Attività pesci assente',
                      'Zona non produttiva oggi',
                      'Orario sbagliato',
                      'Altro'
                    ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _feedbackReason = val),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action
            const Text('Cosa hai fatto?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _action,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'went_fishing',
                    child: Text('Sono andato a pescare')),
                DropdownMenuItem(
                    value: 'stayed_home', child: Text('Sono rimasto a casa')),
                DropdownMenuItem(
                    value: 'changed_location',
                    child: Text('Ho cambiato posto')),
              ],
              onChanged: (value) => setState(() => _action = value!),
            ),

            const SizedBox(height: 20),

            // Outcome (solo se è andato a pescare)
            if (_action == 'went_fishing') ...[
              const Text('Risultato della battuta?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _outcome,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'successful', child: Text('Ottima! 🐟🐟🐟')),
                  DropdownMenuItem(
                      value: 'moderate', child: Text('Discreta 🐟')),
                  DropdownMenuItem(value: 'poor', child: Text('Scarsa 😞')),
                ],
                onChanged: (value) => setState(() => _outcome = value!),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Invia Feedback'),
        ),
      ],
    );
  }
}
