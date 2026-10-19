/// Data classes for the Open-Meteo forecast response.
library;

class Place {
  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country = '',
    this.admin = '',
  });

  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String admin;

  String get subtitle => [admin, country].where((s) => s.isNotEmpty).join(', ');

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        country: (json['country'] as String?) ?? '',
        admin: (json['admin1'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'country': country,
        'admin1': admin,
      };

  @override
  bool operator ==(Object other) =>
      other is Place && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
  });

  final DateTime time;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
}

class HourlyPoint {
  const HourlyPoint(this.time, this.temperature, this.precipitationChance, this.weatherCode);

  final DateTime time;
  final double temperature;
  final int precipitationChance;
  final int weatherCode;
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.min,
    required this.max,
    required this.precipitationChance,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final double min;
  final double max;
  final int precipitationChance;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;
}

class Forecast {
  const Forecast({required this.current, required this.hourly, required this.daily});

  final CurrentWeather current;
  final List<HourlyPoint> hourly;
  final List<DailyForecast> daily;

  /// The next [count] hours starting from the current hour.
  List<HourlyPoint> nextHours([int count = 24]) {
    final from = DateTime(current.time.year, current.time.month, current.time.day, current.time.hour);
    return hourly.where((h) => !h.time.isBefore(from)).take(count).toList();
  }

  /// Parses the response of /v1/forecast. Times are local to the location
  /// because the request uses `timezone=auto`.
  factory Forecast.fromJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    final h = json['hourly'] as Map<String, dynamic>;
    final d = json['daily'] as Map<String, dynamic>;

    List<T> list<T>(Map<String, dynamic> m, String key) => (m[key] as List).cast<T>();
    double toD(num? v) => (v ?? 0).toDouble();

    final hourTimes = list<String>(h, 'time');
    final hourTemps = list<num?>(h, 'temperature_2m');
    final hourRain = list<num?>(h, 'precipitation_probability');
    final hourCodes = list<num?>(h, 'weather_code');

    final dayTimes = list<String>(d, 'time');
    final dayMin = list<num?>(d, 'temperature_2m_min');
    final dayMax = list<num?>(d, 'temperature_2m_max');
    final dayRain = list<num?>(d, 'precipitation_probability_max');
    final dayCodes = list<num?>(d, 'weather_code');
    final sunrise = list<String>(d, 'sunrise');
    final sunset = list<String>(d, 'sunset');

    return Forecast(
      current: CurrentWeather(
        time: DateTime.parse(c['time'] as String),
        temperature: toD(c['temperature_2m'] as num?),
        feelsLike: toD(c['apparent_temperature'] as num?),
        humidity: toD(c['relative_humidity_2m'] as num?).round(),
        windSpeed: toD(c['wind_speed_10m'] as num?),
        weatherCode: toD(c['weather_code'] as num?).toInt(),
        isDay: (c['is_day'] as num?) == 1,
      ),
      hourly: [
        for (var i = 0; i < hourTimes.length; i++)
          HourlyPoint(
            DateTime.parse(hourTimes[i]),
            toD(hourTemps[i]),
            toD(hourRain[i]).round(),
            toD(hourCodes[i]).toInt(),
          ),
      ],
      daily: [
        for (var i = 0; i < dayTimes.length; i++)
          DailyForecast(
            date: DateTime.parse(dayTimes[i]),
            min: toD(dayMin[i]),
            max: toD(dayMax[i]),
            precipitationChance: toD(dayRain[i]).round(),
            weatherCode: toD(dayCodes[i]).toInt(),
            sunrise: DateTime.parse(sunrise[i]),
            sunset: DateTime.parse(sunset[i]),
          ),
      ],
    );
  }
}
