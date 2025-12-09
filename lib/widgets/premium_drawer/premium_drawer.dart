// /lib/widgets/premium_drawer/premium_drawer.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Import dei componenti modulari
import 'premium_drawer_painters.dart'; // Contiene MeshGradientPainter
import 'drawer_header_widgets.dart'; // Contiene PremiumDrawerHeader
import 'drawer_menu_widgets.dart'; // Contiene DrawerMenuList
import 'drawer_footer_widgets.dart'; // Contiene PremiumDrawerFooter

class PremiumDrawer extends StatefulWidget {
  final AnimationController particleController;

  const PremiumDrawer({super.key, required this.particleController});

  @override
  State<PremiumDrawer> createState() => _PremiumDrawerState();
}

class _PremiumDrawerState extends State<PremiumDrawer>
    with TickerProviderStateMixin {
  late AnimationController _scanlineController;
  late Timer _dataTimer;

  // Dati di stato per il footer
  String _lat = "40.813";
  String _lon = "14.208";
  String _mem = "42%";

  @override
  void initState() {
    super.initState();
    // Animazione per l'header
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Simulazione dati vivi per il footer
    _dataTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _lat = "40.8${10 + math.Random().nextInt(90)}";
          _lon = "14.2${05 + math.Random().nextInt(90)}";
          _mem = "${40 + math.Random().nextInt(5)}%";
        });
      }
    });
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    _dataTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.82,
      child: Stack(
        children: [
          // 1. BACKGROUND (Mesh Gradient)
          AnimatedBuilder(
            animation: widget.particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: MeshGradientPainter(widget.particleController.value),
                size: Size.infinite,
              );
            },
          ),

          // 2. GLASS CONTENT
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(30)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF020408).withValues(alpha: 0.92),
                      const Color(0xFF0F172A).withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: const Border(
                      right: BorderSide(color: Colors.white10, width: 1)),
                ),
                child: Column(
                  children: [
                    // HEADER (Passiamo solo il controller richiesto)
                    PremiumDrawerHeader(
                        scanlineController: _scanlineController),

                    const SizedBox(height: 10),

                    // MENU (Nessun parametro richiesto, gestisce la navigazione internamente)
                    const DrawerMenuList(),

                    // FOOTER (Passiamo i dati primitivi richiesti)
                    PremiumDrawerFooter(lat: _lat, lon: _lon, mem: _mem),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
