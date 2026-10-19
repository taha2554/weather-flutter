import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_flutter/models/weather.dart';
import 'package:weather_flutter/models/weather_code.dart';
import 'package:weather_flutter/services/weather_api.dart';
import 'package:weather_flutter/widgets/daily_list.dart';

Map<String, dynamic> sampleForecast() => {
      'current': {
        'time': '2026-10-19T14:15',
        'temperature_2m': 18.4,
        'apparent_temperature': 17.1,
        'relative_humidity_2m': 61,
        'wind_speed_10m': 12.3,
        'weather_code': 2,
        'is_day': 1,
      },
      'hourly': {
        'time': ['2026-10-19T13:00', '2026-10-19T14:00', '2026-10-19T15:00', '2026-10-19T16:00'],
        'temperature_2m': [18.0, 18.4, 18.1, null],
        'precipitation_probability': [0, 5, 20, 35],
        'weather_code': [1, 2, 3, 61],
      },
      'daily': {
        'time': ['2026-10-19', '2026-10-20'],
        'temperature_2m_min': [12.1, 10.4],
        'temperature_2m_max': [19.6, 16.2],
        'precipitation_probability_max': [35, 80],
        'weather_code': [3, 63],
        'sunrise': ['2026-10-19T07:21', '2026-10-20T07:22'],
        'sunset': ['2026-10-19T18:27', '2026-10-20T18:25'],
      },
    };

void main() {
  group('Forecast.fromJson', () {
    final forecast = Forecast.fromJson(sampleForecast());

    test('parses current conditions', () {
      expect(forecast.current.temperature, 18.4);
      expect(forecast.current.humidity, 61);
      expect(forecast.current.isDay, isTrue);
      expect(forecast.current.time, DateTime(2026, 10, 19, 14, 15));
    });

    test('treats null values as zero instead of crashing', () {
      expect(forecast.hourly.last.temperature, 0);
    });

    test('nextHours starts at the current hour', () {
      final next = forecast.nextHours(2);
      expect(next.map((h) => h.time.hour), [14, 15]);
    });

    test('parses daily forecast', () {
      expect(forecast.daily, hasLength(2));
      expect(forecast.daily[1].precipitationChance, 80);
      expect(forecast.daily[0].sunset, DateTime(2026, 10, 19, 18, 27));
    });
  });

  group('WeatherCondition', () {
    test('maps WMO codes', () {
      expect(WeatherCondition.fromCode(0).label, 'Clear sky');
      expect(WeatherCondition.fromCode(63).label, 'Rain');
      expect(WeatherCondition.fromCode(96).label, 'Thunderstorm with hail');
      expect(WeatherCondition.fromCode(1234).label, 'Unknown');
    });

    test('uses a night icon for clear sky after dark', () {
      final clear = WeatherCondition.fromCode(0);
      expect(clear.icon(isDay: false), isNot(clear.icon(isDay: true)));
    });
  });

  group('WeatherApi', () {
    test('searchPlaces sends the query and parses results', () async {
      late Uri requested;
      final api = WeatherApi(
        client: MockClient((req) async {
          requested = req.url;
          return http.Response(
            jsonEncode({
              'results': [
                {'name': 'Erzurum', 'latitude': 39.9, 'longitude': 41.27, 'country': 'Türkiye', 'admin1': 'Erzurum'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final places = await api.searchPlaces('Erzurum');
      expect(requested.queryParameters['name'], 'Erzurum');
      expect(places.single.subtitle, 'Erzurum, Türkiye');
    });

    test('no results returns an empty list', () async {
      final api = WeatherApi(client: MockClient((_) async => http.Response('{"generationtime_ms":0.5}', 200)));
      expect(await api.searchPlaces('qqqqqq'), isEmpty);
    });

    test('short queries do not hit the network', () async {
      var called = false;
      final api = WeatherApi(client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }));
      expect(await api.searchPlaces('a'), isEmpty);
      expect(called, isFalse);
    });

    test('server errors become WeatherException', () async {
      final api = WeatherApi(client: MockClient((_) async => http.Response('oops', 500)));
      const place = Place(name: 'X', latitude: 1, longitude: 2);
      expect(api.forecast(place), throwsA(isA<WeatherException>()));
    });

    test('forecast request asks for local time zone', () async {
      late Uri requested;
      final api = WeatherApi(client: MockClient((req) async {
        requested = req.url;
        return http.Response(jsonEncode(sampleForecast()), 200);
      }));
      await api.forecast(const Place(name: 'X', latitude: 41.0138, longitude: 28.9497));
      expect(requested.queryParameters['timezone'], 'auto');
      expect(requested.queryParameters['latitude'], '41.0138');
    });
  });

  testWidgets('DailyList shows one row per day', (tester) async {
    final forecast = Forecast.fromJson(sampleForecast());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DailyList(days: forecast.daily))));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('20°'), findsOneWidget); // 19.6 rounded
  });
}
