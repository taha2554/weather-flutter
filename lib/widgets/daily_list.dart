import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather.dart';
import '../models/weather_code.dart';

/// 7-day list with a temperature range bar, scaled across the whole week.
class DailyList extends StatelessWidget {
  const DailyList({super.key, required this.days});

  final List<DailyForecast> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final weekMin = days.map((d) => d.min).reduce(math.min);
    final weekMax = days.map((d) => d.max).reduce(math.max);
    final span = math.max(weekMax - weekMin, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(i == 0 ? 'Today' : DateFormat.E().format(days[i].date), style: theme.textTheme.bodyLarge),
                  ),
                  Icon(WeatherCondition.fromCode(days[i].weatherCode).dayIcon, size: 22),
                  SizedBox(
                    width: 40,
                    child: Text(
                      days[i].precipitationChance >= 20 ? '${days[i].precipitationChance}%' : '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
                    ),
                  ),
                  SizedBox(width: 32, child: Text('${days[i].min.round()}°', textAlign: TextAlign.right)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final left = (days[i].min - weekMin) / span * c.maxWidth;
                        final width = math.max((days[i].max - days[i].min) / span * c.maxWidth, 4.0);
                        return Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Positioned(
                              left: left,
                              width: width,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFFFFB74D)]),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 32, child: Text('${days[i].max.round()}°')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
