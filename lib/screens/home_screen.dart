import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather.dart';
import '../models/weather_code.dart';
import '../services/place_store.dart';
import '../services/weather_api.dart';
import '../widgets/daily_list.dart';
import '../widgets/hourly_strip.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api, required this.store});

  final WeatherApi api;
  final PlaceStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Place> _places = [];
  int _selected = 0;
  Forecast? _forecast;
  String? _error;
  bool _loading = true;

  Place? get _place => _places.isEmpty ? null : _places[_selected];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final places = await widget.store.load();
    final index = await widget.store.selectedIndex();
    setState(() {
      _places = places;
      _selected = index.clamp(0, places.length - 1);
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    final place = _place;
    if (place == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forecast = await widget.api.forecast(place);
      if (!mounted || place != _place) return; // user switched place meanwhile
      setState(() => _forecast = forecast);
    } on WeatherException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(int index) async {
    setState(() {
      _selected = index;
      _forecast = null;
    });
    await widget.store.setSelectedIndex(index);
    await _refresh();
  }

  Future<void> _addPlace() async {
    final place = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => SearchScreen(api: widget.api)),
    );
    if (place == null) return;
    final existing = _places.indexOf(place);
    if (existing >= 0) return _select(existing);
    setState(() => _places = [..._places, place]);
    await widget.store.save(_places);
    await _select(_places.length - 1);
  }

  Future<void> _removePlace(int index) async {
    if (_places.length == 1) return;
    final next = [..._places]..removeAt(index);
    setState(() => _places = next);
    await widget.store.save(next);
    await _select(_selected >= next.length ? next.length - 1 : (_selected > index ? _selected - 1 : _selected));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_place?.name ?? 'Weather'),
        actions: [
          IconButton(onPressed: _addPlace, icon: const Icon(Icons.add_location_alt_outlined), tooltip: 'Add place'),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Saved places', style: theme.textTheme.titleMedium),
              ),
              for (var i = 0; i < _places.length; i++)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(_places[i].name),
                  subtitle: _places[i].subtitle.isEmpty ? null : Text(_places[i].subtitle),
                  selected: i == _selected,
                  trailing: _places.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Remove',
                          onPressed: () => _removePlace(i),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _select(i);
                  },
                ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final forecast = _forecast;
    if (forecast == null) {
      return ListView(
        children: [
          const SizedBox(height: 160),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _refresh, child: const Text('Try again')),
                ],
              ),
            ),
        ],
      );
    }

    final current = forecast.current;
    final condition = WeatherCondition.fromCode(current.weatherCode);
    final today = forecast.daily.isNotEmpty ? forecast.daily.first : null;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${current.temperature.round()}°', style: theme.textTheme.displayLarge),
                    Text(condition.label, style: theme.textTheme.titleLarge),
                    if (today != null)
                      Text(
                        'H ${today.max.round()}°  L ${today.min.round()}°',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Icon(condition.icon(isDay: current.isDay), size: 96, color: theme.colorScheme.primary),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(Icons.thermostat, 'Feels like ${current.feelsLike.round()}°'),
              _InfoChip(Icons.water_drop_outlined, 'Humidity ${current.humidity}%'),
              _InfoChip(Icons.air, 'Wind ${current.windSpeed.round()} km/h'),
              if (today != null) ...[
                _InfoChip(Icons.wb_twilight, 'Sunrise ${DateFormat.Hm().format(today.sunrise)}'),
                _InfoChip(Icons.nights_stay_outlined, 'Sunset ${DateFormat.Hm().format(today.sunset)}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Next 24 hours'),
        HourlyStrip(hours: forecast.nextHours(), now: current.time),
        const SizedBox(height: 8),
        const _SectionTitle('7-day forecast'),
        DailyList(days: forecast.daily),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Weather data by Open-Meteo.com',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 18), label: Text(label));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
