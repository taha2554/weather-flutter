import 'dart:async';

import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/weather_api.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.api});

  final WeatherApi api;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Place> _results = [];
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    // wait until the user stops typing for a moment before calling the API
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(text));
  }

  Future<void> _search(String text) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.api.searchPlaces(text);
      if (!mounted || id != _requestId) return;
      setState(() => _results = results);
    } on WeatherException catch (e) {
      if (mounted && id == _requestId) setState(() => _error = e.message);
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'Search city', border: InputBorder.none),
          onChanged: _onChanged,
          onSubmitted: _search,
        ),
        bottom: _loading
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: Builder(
        builder: (context) {
          if (_error != null) return Center(child: Text(_error!));
          if (_results.isEmpty) {
            return Center(
              child: Text(
                _controller.text.trim().length < 2 ? 'Type at least two letters' : 'No places found',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            );
          }
          return ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final place = _results[i];
              return ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(place.name),
                subtitle: Text(place.subtitle),
                onTap: () => Navigator.pop(context, place),
              );
            },
          );
        },
      ),
    );
  }
}
