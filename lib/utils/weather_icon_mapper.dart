// lib/utils/weather_icon_mapper.dart

import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

/// Restituisce l'IconData corretta per un dato codice meteo.
IconData getWeatherIcon(String weatherCode, {bool isDay = true}) {
  //print(
  //    '[WeatherMapper Log] Calcolo icona per codice: $weatherCode, isDay: $isDay');
  final int code = int.tryParse(weatherCode) ?? 0;

  switch (code) {
    // Sereno / Soleggiato / Luna
    case 113:
      return isDay ? WeatherIcons.day_sunny : WeatherIcons.night_clear;
    // Parzialmente nuvoloso
    case 116:
      return isDay ? WeatherIcons.day_cloudy : WeatherIcons.night_alt_cloudy;
    // Nuvoloso
    case 119:
      return isDay
          ? WeatherIcons.cloud
          : WeatherIcons.night_alt_cloudy; // Usa la stessa icona notturna
    // Coperto
    case 122:
      return WeatherIcons.cloudy; // Stessa icona giorno/notte
    // Nebbia
    case 143:
    case 248:
    case 260:
      return isDay ? WeatherIcons.day_fog : WeatherIcons.night_fog;
    // Pioggia leggera
    case 176: // Rovesci sparsi
    case 266: // Pioggerella
    case 293: // Pioviggine leggera
    case 296: // Pioggia leggera
    case 353: // Rovesci leggeri
      return isDay ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;
    // Pioggia moderata/forte
    case 299:
    case 302:
    case 305:
    case 308:
    case 356:
    case 359:
      return isDay ? WeatherIcons.day_rain : WeatherIcons.night_alt_rain;
    // Temporale
    case 200:
    case 386:
    case 389:
    case 392:
    case 395:
      return isDay
          ? WeatherIcons.day_thunderstorm
          : WeatherIcons.night_alt_thunderstorm;
    // Neve
    case 179:
    case 182:
    case 185:
    case 227:
    case 230:
    case 323:
    case 326:
    case 329:
    case 332:
    case 335:
    case 338:
    case 368:
    case 371:
      return isDay ? WeatherIcons.day_snow : WeatherIcons.night_alt_snow;
    // Default
    default:
      return WeatherIcons.na;
  }
}

/// Mappa una stringa emoji-based (es. '☀️') a un'Icona e un Colore.
/// Questa funzione funge da ponte per i dati provenienti dal parsing iniziale in ApiService.
Map<String, dynamic> mapLegacyIconString(String iconString) {
  if (iconString.contains('☀️')) {
    return {'icon': Icons.wb_sunny, 'icon_color': Colors.yellow.shade600};
  }
  if (iconString.contains('🌧️')) {
    return {'icon': Icons.umbrella, 'icon_color': Colors.blue.shade300};
  }
  if (iconString.contains('☁️')) {
    return {'icon': Icons.cloud_outlined, 'icon_color': Colors.grey.shade400};
  }
  // Fallback per icone non riconosciute
  return {'icon': Icons.help_outline, 'icon_color': Colors.grey};
}

/// Restituisce il colore appropriato per l'icona meteo in base
/// al codice e al contesto (giorno/notte) per garantire il contrasto.
Color getWeatherIconColor(String weatherCode, {bool isDay = true}) {
  //print(
  //    '[WeatherMapper Log] Calcolo colore per codice: $weatherCode, isDay: $isDay');
  final int code = int.tryParse(weatherCode) ?? 0;

  // Se è notte, la maggior parte delle icone saranno chiare per contrasto.
  if (!isDay) {
    switch (code) {
      // Temporale notturno -> colore brillante
      case 200:
      case 386:
      case 389:
      case 392:
      case 395:
        return Colors.yellow.shade300; // Un giallo meno intenso per i fulmini
      // Pioggia/Neve notturna -> colore chiaro
      case 176:
      case 263:
      case 266:
      case 293:
      case 296:
      case 299:
      case 302:
      case 305:
      case 308:
      case 353:
      case 356:
      case 359:
      case 179:
      case 182:
      case 185:
      case 227:
      case 230:
      case 323:
      case 326:
      case 329:
      case 332:
      case 335:
      case 338:
      case 368:
      case 371:
        return Colors.cyan.shade100;
      // Per tutto il resto (nuvoloso, nebbia) usiamo un grigio chiaro
      default:
        return Colors.grey.shade400;
    }
  }

  // Se è giorno
  switch (code) {
    // Soleggiato
    case 113:
      return Colors.amber;
    // Nuvoloso
    case 116:
    case 119:
    case 122:
      return Colors.grey.shade500;
    // Pioggia/Rovesci
    case 176:
    case 263:
    case 266:
    case 293:
    case 296:
    case 299:
    case 302:
    case 305:
    case 308:
    case 353:
    case 356:
    case 359:
      return Colors.cyan;
    // Temporale
    case 200:
    case 386:
    case 389:
    case 392:
    case 395:
      return Colors.deepPurple.shade300; // Indaco per il giorno
    // Neve
    case 179:
    case 182:
    case 185:
    case 227:
    case 230:
    case 323:
    case 326:
    case 329:
    case 332:
    case 335:
    case 338:
    case 368:
    case 371:
      return Colors.white;
    // Default (es. Nebbia)
    default:
      return Colors.grey.shade400;
  }
}

/// Restituisce l'IconData corretta per la fase lunare
/// basandosi sulla stringa di testo fornita dall'API.
IconData getMoonPhaseIcon(String moonPhaseText) {
  //print('[WeatherMapper Log] Calcolo icona per fase lunare: "$moonPhaseText"');
  // Normalizza la stringa per un matching robusto
  final phase = moonPhaseText.toLowerCase().trim();

  if (phase == 'new moon') return WeatherIcons.moon_new;
  if (phase == 'waxing crescent') return WeatherIcons.moon_waxing_crescent_3;
  if (phase == 'first quarter') return WeatherIcons.moon_first_quarter;
  if (phase == 'waxing gibbous') return WeatherIcons.moon_waxing_gibbous_3;
  if (phase == 'full moon') return WeatherIcons.moon_full;
  if (phase == 'waning gibbous') return WeatherIcons.moon_waning_gibbous_3;
  if (phase == 'last quarter' || phase == 'third quarter')
    return WeatherIcons.moon_third_quarter; // Aggiunto 'last quarter'
  if (phase == 'waning crescent') return WeatherIcons.moon_waning_crescent_3;

  // Fallback se il testo è vuoto o non riconosciuto
  //print(
  //    '[WeatherMapper Log] Fase lunare non riconosciuta: "$phase". Uso fallback.');
  return WeatherIcons.na;
}
