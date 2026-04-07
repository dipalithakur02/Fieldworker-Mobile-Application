import 'package:dio/dio.dart';

class WeatherService {
  static const String apiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<Map<String, dynamic>?> getCurrentWeather(
      double lat, double lon) async {
    try {
      final response = await Dio().get(
        '$baseUrl/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
          'units': 'metric',
        },
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>?> getForecast(double lat, double lon) async {
    try {
      final response = await Dio().get(
        '$baseUrl/forecast',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
          'units': 'metric',
        },
      );
      return response.data['list'];
    } catch (e) {
      return null;
    }
  }
}
