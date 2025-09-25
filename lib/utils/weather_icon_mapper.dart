// lib/utils/weather_icon_mapper.dart

import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

IconData getWeatherIcon(String weatherCode) {
  final int code = int.tryParse(weatherCode) ?? 0;

  switch (code) {
    // Soleggiato
    case 113:
      return WeatherIcons.day_sunny;
    // Parzialmente nuvoloso
    case 116:
      return WeatherIcons.day_cloudy;
    // Nuvoloso
    case 119:
      return WeatherIcons.cloud;
    // Coperto
    case 122:
      return WeatherIcons.cloudy;
    // Nebbia
    case 143:
    case 248:
    case 260:
      return WeatherIcons.fog;
    // Pioggia leggera
    case 176:
    case 263:
    case 266:
    case 293:
    case 296:
    case 353:
      return WeatherIcons.showers;
    // Pioggia moderata/forte
    case 299:
    case 302:
    case 305:
    case 308:
    case 356:
    case 359:
      return WeatherIcons.rain;
    // Temporale
    case 200:
    case 386:
    case 389:
    case 392:
    case 395:
      return WeatherIcons.thunderstorm;
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
      return WeatherIcons.snow;
    default:
      return WeatherIcons.na;
  }
}