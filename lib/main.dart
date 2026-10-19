import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/place_store.dart';
import 'services/weather_api.dart';

void main() {
  runApp(WeatherApp(api: WeatherApi(), store: PlaceStore()));
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key, required this.api, required this.store});

  final WeatherApi api;
  final PlaceStore store;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3A7BD5);
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      home: HomeScreen(api: api, store: store),
    );
  }
}
