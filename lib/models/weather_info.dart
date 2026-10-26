/// Represents current weather data fetched from the National Weather Service API.
class WeatherInfo {
  final int temperature;
  final String temperatureUnit;
  final String shortForecast;
  final String windSpeed;
  final String windDirection;
  final int? humidity;
  final int? precipitationChance;

  const WeatherInfo({
    required this.temperature,
    this.temperatureUnit = 'F',
    required this.shortForecast,
    required this.windSpeed,
    required this.windDirection,
    this.humidity,
    this.precipitationChance,
  });

  /// Factory constructor to parse NWS period JSON (from forecastHourly endpoint).
  factory WeatherInfo.fromNwsJson(Map<String, dynamic> json) {
    final rawHumidity = json['relativeHumidity'];
    int? parsedHumidity;
    if (rawHumidity is Map && rawHumidity['value'] != null) {
      parsedHumidity = (rawHumidity['value'] as num).toInt();
    }

    final rawPrecipitation = json['probabilityOfPrecipitation'];
    int? parsedPrecipitation;
    if (rawPrecipitation is Map && rawPrecipitation['value'] != null) {
      parsedPrecipitation = (rawPrecipitation['value'] as num).toInt();
    }

    return WeatherInfo(
      temperature: (json['temperature'] as num?)?.toInt() ?? 0,
      temperatureUnit: (json['temperatureUnit'] as String?) ?? 'F',
      shortForecast: (json['shortForecast'] as String?) ?? 'Clear',
      windSpeed: (json['windSpeed'] as String?) ?? 'Calm',
      windDirection: (json['windDirection'] as String?) ?? '',
      humidity: parsedHumidity,
      precipitationChance: parsedPrecipitation,
    );
  }
}
