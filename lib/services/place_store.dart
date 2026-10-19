import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';

/// Remembers saved places and which one was open last.
class PlaceStore {
  static const _placesKey = 'saved_places';
  static const _selectedKey = 'selected_place';

  static const defaultPlace = Place(name: 'Istanbul', latitude: 41.0138, longitude: 28.9497, country: 'Türkiye');

  Future<List<Place>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_placesKey);
    if (raw == null) return [defaultPlace];
    final places = <Place>[];
    for (final item in raw) {
      try {
        places.add(Place.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {
        // skip corrupted entries
      }
    }
    return places.isEmpty ? [defaultPlace] : places;
  }

  Future<void> save(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_placesKey, places.map((p) => jsonEncode(p.toJson())).toList());
  }

  Future<int> selectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_selectedKey) ?? 0;
  }

  Future<void> setSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedKey, index);
  }
}
