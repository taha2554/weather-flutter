import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherException implements Exception {
  WeatherException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Client for Open-Meteo's geocoding and forecast APIs. Both are free and need no API key.
class WeatherApi {
  WeatherApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _geoHost = 'geocoding-api.open-meteo.com';
  static const _forecastHost = 'api.open-meteo.com';

  Future<List<Place>> searchPlaces(String query, {String language = 'en'}) async {
    final q = query.trim();
    if (q.length < 2) return [];
    final uri = Uri.https(_geoHost, '/v1/search', {
      'name': q,
      'count': '8',
      'language': language,
      'format': 'json',
    });
    final json = await _get(uri);
    final results = json['results'] as List?;
    return results == null ? [] : results.map((r) => Place.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Forecast> forecast(Place place) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': place.latitude.toStringAsFixed(4),
      'longitude': place.longitude.toStringAsFixed(4),
      'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day',
      'hourly': 'temperature_2m,precipitation_probability,weather_code',
      'daily': 'temperature_2m_min,temperature_2m_max,precipitation_probability_max,weather_code,sunrise,sunset',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    return Forecast.fromJson(await _get(uri));
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 12));
    } catch (_) {
      throw WeatherException('Could not connect. Check your internet connection.');
    }
    if (res.statusCode != 200) {
      throw WeatherException('Weather service returned an error (${res.statusCode}).');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
