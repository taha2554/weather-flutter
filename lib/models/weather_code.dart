import 'package:flutter/material.dart';

/// WMO weather interpretation codes used by Open-Meteo.
/// https://open-meteo.com/en/docs (section "WMO Weather interpretation codes")
class WeatherCondition {
  const WeatherCondition(this.label, this.dayIcon, [IconData? nightIcon]) : nightIcon = nightIcon ?? dayIcon;

  final String label;
  final IconData dayIcon;
  final IconData nightIcon;

  IconData icon({bool isDay = true}) => isDay ? dayIcon : nightIcon;

  static WeatherCondition fromCode(int code) {
    return switch (code) {
      0 => const WeatherCondition('Clear sky', Icons.wb_sunny, Icons.nightlight_round),
      1 => const WeatherCondition('Mainly clear', Icons.wb_sunny, Icons.nightlight_round),
      2 => const WeatherCondition('Partly cloudy', Icons.wb_cloudy, Icons.cloud),
      3 => const WeatherCondition('Overcast', Icons.cloud),
      45 || 48 => const WeatherCondition('Fog', Icons.foggy),
      51 || 53 || 55 => const WeatherCondition('Drizzle', Icons.grain),
      56 || 57 => const WeatherCondition('Freezing drizzle', Icons.ac_unit),
      61 || 63 => const WeatherCondition('Rain', Icons.water_drop),
      65 => const WeatherCondition('Heavy rain', Icons.water_drop),
      66 || 67 => const WeatherCondition('Freezing rain', Icons.ac_unit),
      71 || 73 || 75 || 77 => const WeatherCondition('Snow', Icons.ac_unit),
      80 || 81 || 82 => const WeatherCondition('Rain showers', Icons.umbrella),
      85 || 86 => const WeatherCondition('Snow showers', Icons.ac_unit),
      95 => const WeatherCondition('Thunderstorm', Icons.thunderstorm),
      96 || 99 => const WeatherCondition('Thunderstorm with hail', Icons.thunderstorm),
      _ => const WeatherCondition('Unknown', Icons.help_outline),
    };
  }
}
