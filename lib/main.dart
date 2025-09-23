// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/forecast_screen.dart'; // Importa la schermata principale

void main() {
  runApp(const PescaApp());
}

class PescaApp extends StatelessWidget {
  const PescaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Previsioni Pesca',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D121B),
        fontFamily: 'Roboto',
      ),
      home: const ForecastScreen(), // L'app ora parte da qui
    );
  }
}