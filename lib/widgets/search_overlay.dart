// lib/widgets/search_overlay.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart'; // <--- ERRORE CORRETTO QUI
import '../services/api_service.dart';
import 'glassmorphism_card.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onGpsSearch;
  final Function(String location, String name) onLocationSelected;

  const SearchOverlay({
    required this.onClose,
    required this.onGpsSearch,
    required this.onLocationSelected,
    super.key,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacity;
  late Animation<Offset> _position;

  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService();

  final List<Map<String, String>> popularLocations = [
    {'name': 'Posillipo, Napoli', 'coords': '40.813238367880984,14.208944303204635'},
    {'name': 'Napoli, Italia', 'coords': '40.852,14.268'},
    {'name': 'Genova, Italia', 'coords': '44.4056,8.9463'},
    {'name': 'Livorno, Italia', 'coords': '43.551,10.308'},
    {'name': 'Civitavecchia, Italia', 'coords': '42.0927,11.796'},
    {'name': 'Cagliari, Italia', 'coords': '39.2238,9.1217'}
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _position = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      
      setState(() => _isLoading = true);
      
      final results = await _apiService.fetchAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: _opacity,
        child: GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: GestureDetector(
                onTap: () {},
                child: SlideTransition(
                  position: _position,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 16,
                          right: 16),
                      child: _buildSearchPanel(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    final bool isSearching = _textController.text.isNotEmpty;
    final List<Map<String, String>> currentList = isSearching
        ? _suggestions.map((s) => {'name': s['name'] as String, 'coords': "${s['lat']},${s['lon']}"}).toList()
        : popularLocations;

    return GlassmorphismCard(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            TextField(
              controller: _textController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Cerca una località...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                suffixIcon: isSearching
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () => _textController.clear())
                    : null,
              ),
            ),
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSearchAction(Icons.gps_fixed, "Posizione", widget.onGpsSearch),
                  _buildSearchAction(Icons.star, "Preferiti", () {})
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? const Center(key: ValueKey('loader'), child: CircularProgressIndicator(color: Colors.white))
                    : (isSearching && currentList.isEmpty && _textController.text.length >= 3)
                        ? const Center(key: ValueKey('no_results'), child: Text('Nessuna località trovata.', style: TextStyle(color: Colors.white70)))
                        : ListView(
                            key: const ValueKey('results_list'),
                            children: currentList.map((loc) => ListTile(
                                leading: const Icon(Icons.location_on_outlined, color: Colors.white70),
                                title: _buildRichTextSuggestion(loc['name']!),
                                onTap: () => widget.onLocationSelected(loc['coords']!, loc['name']!.split(',')[0])),
                              ).toList(),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichTextSuggestion(String fullName) {
    final parts = fullName.split(',');
    if (parts.isEmpty) return const Text('');

    final mainName = parts[0];
    final secondaryInfo = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Colors.white),
        children: [
          TextSpan(text: mainName, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (secondaryInfo.isNotEmpty)
            TextSpan(text: ', $secondaryInfo', style: const TextStyle(color: Colors.white70)),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSearchAction(IconData icon, String label, VoidCallback onPressed) =>
      TextButton.icon(
        icon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        label: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
      );
}