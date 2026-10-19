import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather.dart';
import '../models/weather_code.dart';

class HourlyStrip extends StatelessWidget {
  const HourlyStrip({super.key, required this.hours, required this.now});

  final List<HourlyPoint> hours;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: hours.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final h = hours[i];
          final isNow = i == 0;
          return Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isNow ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isNow ? 'Now' : DateFormat.H().format(h.time), style: theme.textTheme.labelMedium),
                Icon(WeatherCondition.fromCode(h.weatherCode).icon(isDay: h.time.hour >= 6 && h.time.hour < 20)),
                Text('${h.temperature.round()}°', style: theme.textTheme.titleSmall),
                Text(
                  h.precipitationChance > 0 ? '${h.precipitationChance}%' : '',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
