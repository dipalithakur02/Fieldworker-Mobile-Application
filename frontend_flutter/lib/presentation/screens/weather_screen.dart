import 'package:flutter/material.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/location_service.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoading = true);
    final position = await LocationService.getCurrentLocation();

    if (position != null) {
      final weather = await WeatherService.getCurrentWeather(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _weatherData = weather;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather'),
        backgroundColor: Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWeather,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _weatherData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Unable to fetch weather data'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWeather,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                _weatherData!['name'] ?? 'Unknown',
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 16),
                              Icon(
                                _getWeatherIcon(
                                    _weatherData!['weather'][0]['main']),
                                size: 100,
                                color: Color(0xFF2E7D32),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '${_weatherData!['main']['temp'].round()}°C',
                                style: TextStyle(
                                    fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _weatherData!['weather'][0]['description'],
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildWeatherDetail(
                                    'Humidity',
                                    '${_weatherData!['main']['humidity']}%',
                                    Icons.water_drop,
                                  ),
                                  _buildWeatherDetail(
                                    'Wind',
                                    '${_weatherData!['wind']['speed']} m/s',
                                    Icons.air,
                                  ),
                                  _buildWeatherDetail(
                                    'Pressure',
                                    '${_weatherData!['main']['pressure']} hPa',
                                    Icons.compress,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF2E7D32)),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }
}
