import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// ------ 1. MODELLI DATI ------
class ScoreReason {
  final String icon, text, points, type;
  const ScoreReason({required this.icon, required this.text, required this.points, required this.type});
  factory ScoreReason.fromJson(Map<String, dynamic> json) => ScoreReason( icon: json['icon'] ?? 'pressure', text: json['text'] ?? 'N/D', points: json['points'] ?? '+0.0', type: json['type'] ?? 'neutral');
}
class ForecastData {
  final String giornoNome, giornoData, meteoIcon, temperaturaAvg, tempMinMax, ventoDati, pressione, umidita, mare, altaMarea, bassaMarea, alba, tramonto, finestraMattino, finestraSera;
  final double pescaScoreNumeric;
  final List<ScoreReason> pescaScoreReasons;
  final List<Map<String, dynamic>> hourlyData;
  final List<Map<String, dynamic>> weeklyData;
  ForecastData({
    required this.giornoNome, required this.giornoData, required this.meteoIcon, required this.temperaturaAvg, required this.tempMinMax, required this.ventoDati, required this.pressione,
    required this.umidita, required this.mare, required this.altaMarea, required this.bassaMarea, required this.alba, required this.tramonto, required this.finestraMattino,
    required this.finestraSera, required this.pescaScoreNumeric, required this.pescaScoreReasons, required this.hourlyData, required this.weeklyData,
  });
  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final tempAvg = json['temperaturaAvg']?.toString() ?? 'N/D'; final tempMin = json['temperaturaMin']?.toString() ?? '?'; final tempMax = json['temperaturaMax']?.toString() ?? '?';
    final maree = json['maree'] ?? 'Alta: N/D | Bassa: N/D'; final mareeParts = maree.split('|');
    final scoreData = json['pescaScoreData'] as Map<String, dynamic>? ?? {'numericScore': 0.0, 'reasons': []};
    final reasonsList = scoreData['reasons'] as List? ?? [];
    return ForecastData(
      giornoNome: json['giornoNome'] ?? 'N/D', giornoData: json['giornoData'] ?? 'N/D', meteoIcon: json['meteoIcon'] ?? '❓', temperaturaAvg: '$tempAvg°', tempMinMax: 'Max: $tempMax° Min: $tempMin°',
      ventoDati: json['ventoDati'] ?? 'N/D', pressione: "${json['pressione'] ?? 'N/D'} hPa ${json['trendPressione'] ?? ''}", umidita: '${json['umidita'] ?? 'N/D'}%',
      mare: "${json['acronimoMare'] ?? ''} ${json['temperaturaAcqua'] ?? ''}° ${json['velocitaCorrente'] ?? ''} kn",
      altaMarea: mareeParts.isNotEmpty ? mareeParts[0].replaceFirst('Alta:', '').trim() : 'N/D', bassaMarea: mareeParts.length > 1 ? mareeParts[1].replaceFirst('Bassa:', '').trim() : 'N/D',
      alba: (json['alba'] as String?)?.replaceFirst('☀️', '').trim() ?? 'N/D', tramonto: (json['tramonto'] as String?)?.trim() ?? 'N/D',
      finestraMattino: json['finestraMattino']?['orario'] ?? 'N/D', finestraSera: json['finestraSera']?['orario'] ?? 'N/D',
      pescaScoreNumeric: (scoreData['numericScore'] as num?)?.toDouble() ?? 0.0, pescaScoreReasons: reasonsList.map((r) => ScoreReason.fromJson(r)).toList(),
      hourlyData: mockHourlyData, weeklyData: mockWeeklyData,
    );
  }
}
// ------ 2. APP PRINCIPALE ------
void main() { runApp(const PescaApp()); }
class PescaApp extends StatelessWidget { const PescaApp({super.key}); @override Widget build(BuildContext context) { return MaterialApp( debugShowCheckedModeBanner: false, title: 'Previsioni Pesca', theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0D121B), fontFamily: 'Roboto'), home: const ForecastScreen()); } }

// ------ 3. SCHERMATA PRINCIPALE ------
class ForecastScreen extends StatefulWidget { const ForecastScreen({super.key}); @override State<ForecastScreen> createState() => _ForecastScreenState(); }
class _ForecastScreenState extends State<ForecastScreen> {
  Future<List<ForecastData>>? _forecastFuture;
  String _currentLocationName = "Posillipo";
  OverlayEntry? _searchOverlayEntry; // Usiamo un OverlayEntry per il pannello

  @override
  void initState() {
    super.initState();
    _loadForecast('40.813238367880984,14.208944303204635', "Posillipo");
  }

  void _loadForecast(String location, String name) {
    if (!mounted) return;
    setState(() {
      _currentLocationName = name;
      _forecastFuture = _fetchForecastData(location);
    });
  }

  Future<List<ForecastData>> _fetchForecastData(String location) async {
    final url = Uri.parse('https://pesca-api.onrender.com/api/forecast?location=$location');
    final response = await http.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return (decoded['forecast'] as List).map((json) => ForecastData.fromJson(json)).toList();
    } else {
      throw Exception('Errore nel caricare le previsioni (Codice: ${response.statusCode})');
    }
  }
  
  void _onGpsSearch() async { /* ... la sua logica GPS qui ... */ }
  void _onLocationSelected(String location, String name) {
    _removeSearchOverlay();
    _loadForecast(location, name);
  }

  // NUOVA LOGICA PER GESTIRE L'OVERLAY
  void _toggleSearchPanel() {
    if (_searchOverlayEntry == null) {
      print('[Search Log] Creazione e inserimento overlay.');
      _searchOverlayEntry = _createSearchOverlay();
      Overlay.of(context).insert(_searchOverlayEntry!);
    } else {
      _removeSearchOverlay();
    }
  }

  void _removeSearchOverlay() {
    print('[Search Log] Rimozione overlay.');
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  OverlayEntry _createSearchOverlay() {
    return OverlayEntry(
      builder: (context) => SearchOverlay(
        onClose: _toggleSearchPanel,
        onLocationSelected: _onLocationSelected,
        onGpsSearch: _onGpsSearch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          FutureBuilder<List<ForecastData>>(
            future: _forecastFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
              if (snapshot.hasError) return Center(child: Text('Errore: ${snapshot.error}', style: const TextStyle(color: Colors.white, backgroundColor: Colors.black54), textAlign: TextAlign.center));
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nessun dato.', style: TextStyle(color: Colors.white)));
              
              final forecasts = snapshot.data!;
              return PageView.builder(
                itemCount: forecasts.length,
                itemBuilder: (context, index) {
                  return ForecastPage(data: forecasts[index], locationName: _currentLocationName, onSearchTap: _toggleSearchPanel);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---- 4. WIDGET DI PAGINA GIORNALIERA ----
class ForecastPage extends StatelessWidget {
  final ForecastData data; final String locationName; final VoidCallback onSearchTap;
  const ForecastPage({required this.data, required this.locationName, required this.onSearchTap, super.key});
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent, flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: Colors.black.withOpacity(0.1)))), elevation: 0, pinned: true, centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}), title: Text(locationName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 22)),
          actions: [ Padding(padding: const EdgeInsets.only(right: 8.0), child: IconButton(icon: const Icon(Icons.search), onPressed: onSearchTap)) ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([
            MainHeroModule(data: data),
            const SizedBox(height: 20),
            GlassmorphismCard(title: "PREVISIONI NELLE PROSSIME ORE", child: HourlyForecast(hourlyData: data.hourlyData)),
            const SizedBox(height: 20),
            GlassmorphismCard(title: "PREVISIONI A 7 GIORNI", child: WeeklyForecast(weeklyData: data.weeklyData)),
          ])),
        ),
      ],
    );
  }
}
// ------ 5. TUTTI I WIDGET COMPONENTI ------
class GlassmorphismCard extends StatelessWidget {
  final Widget child; final String? title; const GlassmorphismCard({required this.child, this.title, super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(22), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(padding: const EdgeInsets.all(20.0), decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.15))), child: title != null ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title!.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)), const Divider(color: Colors.white24, height: 24), child]) : child)));
}
class MainHeroModule extends StatelessWidget {
  final ForecastData data; const MainHeroModule({required this.data, super.key});
  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(data.giornoNome.toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)), Text(data.giornoData, style: const TextStyle(fontSize: 14, color: Colors.white70))]),
          const Icon(Icons.wb_sunny_rounded, size: 48, color: Colors.amber),
        ]),
        const SizedBox(height: 8), Text(data.temperaturaAvg, style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w200, height: 1.1)), Text(data.tempMinMax, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)), const SizedBox(height: 20),
        GestureDetector(onLongPress: () => showScoreDetailsDialog(context, data.pescaScoreReasons), child: FishingScoreIndicator(score: data.pescaScoreNumeric)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ _buildWindowItem("MATTINO", data.finestraMattino), Container(height: 30, width: 1, color: Colors.white.withOpacity(0.2)), _buildWindowItem("SERA", data.finestraSera)]),
        const Divider(color: Colors.white24, height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ _buildInfoItem('Vento', data.ventoDati), _buildInfoItem('Mare', data.mare), _buildInfoItem('Umidità', data.umidita) ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ _buildInfoItem('Pressione', data.pressione), _buildInfoItem('Alta Marea', data.altaMarea), _buildInfoItem('Bassa Marea', data.bassaMarea) ]),
      ])
    );
  }
  Widget _buildInfoItem(String label, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]));
  Widget _buildWindowItem(String label, String time) { bool sconsigliato = time.toLowerCase() == 'sconsigliato'; return Expanded(child: Column(children: [Text(label, style: TextStyle(fontSize: 11, color: Colors.cyan[200], fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(time, style: TextStyle(fontSize: sconsigliato ? 14 : 16, fontWeight: sconsigliato ? FontWeight.normal : FontWeight.bold, color: sconsigliato ? Colors.white70 : Colors.white))])); }
}
class FishingScoreIndicator extends StatelessWidget {
  final double score; const FishingScoreIndicator({required this.score, super.key});
  @override
  Widget build(BuildContext context) { int fullFish = score.floor(); double lastFishOpacity = score - fullFish; List<Widget> fishIcons = []; for (int i = 0; i < 5; i++) { Color color = Colors.white.withOpacity(0.3); if (i < fullFish) { color = const Color(0xFF66CCCC); } else if (i == fullFish && lastFishOpacity > 0.1) { color = const Color(0xFF66CCCC).withOpacity(lastFishOpacity); } fishIcons.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 2.0), child: Icon(Icons.phishing, size: 30, color: color))); } return Row(mainAxisAlignment: MainAxisAlignment.center, children: fishIcons); }
}
class HourlyForecast extends StatelessWidget {
  final List<Map<String, dynamic>> hourlyData; const HourlyForecast({required this.hourlyData, super.key});
  @override
  Widget build(BuildContext context) { return SizedBox(height: 90, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: hourlyData.length, itemBuilder: (context, index) { final data = hourlyData[index]; bool isNow = index == 0; return Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ Text(data['time']!, style: TextStyle(fontSize: 12, color: isNow ? Colors.white : Colors.white70, fontWeight: isNow ? FontWeight.bold : FontWeight.normal)), Icon(data['icon'], color: isNow ? Colors.yellow.shade600 : Colors.white, size: 28), Text(data['temp']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])); })); }
}
class WeeklyForecast extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData; const WeeklyForecast({required this.weeklyData, super.key});
  @override
  Widget build(BuildContext context) { return Column(children: weeklyData.map((data) => _buildWeeklyRow(data)).toList()); }
  Widget _buildWeeklyRow(Map<String, dynamic> data) { return Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Row(children: [ Expanded(flex: 3, child: Text(data['day'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))), Expanded(flex: 2, child: Icon(data['icon'], color: data['icon_color'], size: 28)), Expanded(flex: 2, child: Text("${data['min']}°", style: const TextStyle(fontSize: 18, color: Colors.white70))), Expanded(flex: 5, child: _buildTempBar(data['min'], data['max'])), Expanded(flex: 2, child: Text("${data['max']}°", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))) ])); }
  Widget _buildTempBar(int min, int max) { const double totalMin = 10, totalMax = 35, totalRange = totalMax - totalMin; double startFraction = (min - totalMin) / totalRange; double widthFraction = (max - min) / totalRange; return Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Container(height: 5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2.5)), child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: 1.0, child: Container(margin: EdgeInsets.only(left: 100 * startFraction.clamp(0.0, 1.0)), width: 100 * widthFraction.clamp(0.0, 1.0), decoration: BoxDecoration(borderRadius: BorderRadius.circular(2.5), gradient: const LinearGradient(colors: [Colors.cyan, Colors.yellow, Colors.orange]))))))); }
}

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
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;

  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  final TextEditingController _controllerTxt = TextEditingController();

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
    _controllerTxt.addListener(() { if (mounted) setState(() {}); });
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _position = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controllerTxt.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      if (query.length < 3) {
        setState(() { _isLoading = false; _suggestions = []; });
        return;
      }
      
      setState(() => _isLoading = true);
      final url = Uri.parse('https://pesca-api.onrender.com/api/autocomplete?text=${Uri.encodeComponent(query)}');
      try {
        final response = await http.get(url).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200 && mounted) {
          final decodedBody = json.decode(response.body);
          if (decodedBody is List) setState(() => _suggestions = decodedBody);
        } else { if (mounted) setState(() => _suggestions = []); }
      } catch (e) { if (mounted) setState(() => _suggestions = []);
      } finally { if (mounted) setState(() => _isLoading = false); }
    });
  }
  
  // ***** WIDGET BUILD AGGIORNATO CON ANIMATEDSWITCHER E NUOVO STILE *****
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
                      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16),
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
    final bool isSearching = _controllerTxt.text.isNotEmpty;
    final List<Map<String, String>> currentList = isSearching
      ? _suggestions.map((s) => {'name': s['name'] as String, 'coords': "${s['lat']},${s['lon']}"}).toList()
      : popularLocations;

    return GlassmorphismCard(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            TextField( controller: _controllerTxt, onChanged: _onSearchChanged, autofocus: true, style: const TextStyle(color: Colors.white, fontSize: 18), decoration: InputDecoration(hintText: 'Cerca una località...', prefixIcon: const Icon(Icons.search, color: Colors.white70), border: InputBorder.none, suffixIcon: isSearching ? IconButton(icon: const Icon(Icons.close), onPressed: () => _controllerTxt.clear()) : null)),
            const Divider(color: Colors.white24),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildSearchAction(Icons.gps_fixed, "Posizione", widget.onGpsSearch), _buildSearchAction(Icons.star, "Preferiti", (){})])),
            const Divider(color: Colors.white24),
            Expanded(
              child: AnimatedSwitcher( // NUOVA ANIMAZIONE
                duration: const Duration(milliseconds: 300),
                child: _isLoading 
                  ? const Center(key: ValueKey('loader'), child: CircularProgressIndicator(color: Colors.white))
                  : (isSearching && currentList.isEmpty) 
                    ? const Center(key: ValueKey('no_results'), child: Text('Nessuna località trovata.', style: TextStyle(color: Colors.white70)))
                    : ListView(
                        key: const ValueKey('results_list'),
                        children: currentList.map((loc) => ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: Colors.white70), // NUOVA ICONA
                          title: _buildRichTextSuggestion(loc['name']!), // NUOVO TESTO STILIZZATO
                          onTap: () => widget.onLocationSelected(loc['coords']!, loc['name']!.split(',')[0]))
                        ).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // NUOVO WIDGET HELPER per la gerarchia del testo
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
          if(secondaryInfo.isNotEmpty)
            TextSpan(text: ', $secondaryInfo', style: const TextStyle(color: Colors.white70)),
        ]
      ),
    );
  }

  Widget _buildSearchAction(IconData icon, String label, VoidCallback onPressed) => TextButton.icon(
    icon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
    label: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed
  );
}


void showScoreDetailsDialog(BuildContext context, List<ScoreReason> reasons) {
  showGeneralDialog(context: context, barrierDismissible: true, barrierLabel: 'Score Details', barrierColor: Colors.black.withOpacity(0.5), transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) => ScoreDetailsDialog(reasons: reasons),
    transitionBuilder: (context, anim1, anim2, child) => BackdropFilter(filter: ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value), child: FadeTransition(opacity: anim1, child: child)));
}
class ScoreDetailsDialog extends StatelessWidget {
  final List<ScoreReason> reasons; const ScoreDetailsDialog({required this.reasons, super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: Colors.transparent, elevation: 0, child: GlassmorphismCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Column(mainAxisSize: MainAxisSize.min, children: [ const Text('Analisi Punteggio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 20), ...List.generate(reasons.length, (index) => AnimatedListItem(index: index, child: _ScoreReasonListItem(reason: reasons[index]))), const SizedBox(height: 10), TextButton(child: const Text('Chiudi', style: TextStyle(color: Colors.white70)), onPressed: () => Navigator.of(context).pop()) ]))));
  }
}

class _ScoreReasonListItem extends StatelessWidget {
  final ScoreReason reason; const _ScoreReasonListItem({required this.reason});
  @override
  Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [ Icon(_getIconForReason(reason.icon), color: Colors.white70, size: 24), const SizedBox(width: 16), Expanded(child: Text(reason.text, style: const TextStyle(color: Colors.white))), Text(reason.points, style: TextStyle(color: reason.type == 'positive' ? Colors.greenAccent : (reason.type == 'negative' ? Colors.redAccent : Colors.white70), fontWeight: FontWeight.bold)) ])); }
  IconData _getIconForReason(String iconName) {
    switch (iconName) {
      case 'pressure_down': return Icons.arrow_downward_rounded; case 'pressure_up': return Icons.arrow_upward_rounded; case 'wind': return Icons.air;
      case 'moon': return Icons.nightlight_round; case 'clouds': return Icons.cloud_queue; case 'waves': return Icons.waves;
      case 'water_temp': return Icons.thermostat; case 'currents': return Icons.swap_horiz_rounded; default: return Icons.info_outline;
    }
  }
}

class AnimatedListItem extends StatefulWidget {
  final int index; final Widget child; const AnimatedListItem({required this.index, required this.child, super.key});
  @override State<AnimatedListItem> createState() => _AnimatedListItemState();
}
class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _opacity; late Animation<Offset> _position;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    final delay = widget.index * 60; // Leggero ritardo per effetto cascata
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Interval(delay / 1000, 1.0, curve: Curves.easeOut)));
    _position = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Interval(delay / 1000, 1.0, curve: Curves.easeOut)));
    _controller.forward();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _position, child: widget.child));
}
// ------ DATI FINTI ------
final List<Map<String, dynamic>> mockHourlyData = [{'time': 'Adesso','icon': Icons.cloud,'temp': '23°'}, {'time': '15:00','icon': Icons.wb_sunny,'temp': '24°'}];
final List<Map<String, dynamic>> mockWeeklyData = [{'day': 'Oggi', 'icon': Icons.wb_cloudy, 'icon_color': Colors.white, 'min': 21, 'max': 25}, {'day': 'Mer','icon': Icons.wb_sunny,'icon_color': Colors.yellow, 'min': 20, 'max': 24}];