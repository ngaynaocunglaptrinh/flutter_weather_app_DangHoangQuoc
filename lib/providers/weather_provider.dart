import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

enum WeatherState {
  initial,
  loading,
  loaded,
  error,
}

class WeatherProvider extends ChangeNotifier {
  final WeatherService weatherService;
  final LocationService locationService;
  final StorageService storageService;

  WeatherProvider({
    required this.weatherService,
    required this.locationService,
    required this.storageService,
  });

  WeatherModel? _currentWeather;
  List<ForecastModel> _forecast = [];
  WeatherState _state = WeatherState.initial;
  String _errorMessage = '';
  bool _isCachedData = false;
  DateTime? _lastUpdateTime;
  String _temperatureUnit = 'C';
  WeatherModel? get currentWeather => _currentWeather;
  List<ForecastModel> get forecast => _forecast;
  WeatherState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isCachedData => _isCachedData;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  String get temperatureUnit => _temperatureUnit;

  Future<void> init() async {
    _temperatureUnit = await storageService.getTemperatureUnit();
    await fetchWeatherByLocation();
  }

  double convertTemperature(double celsius) {
    if (_temperatureUnit == 'F') {
      return celsius * 9 / 5 + 32;
    }

    return celsius;
  }

  String get temperatureSymbol {
    return _temperatureUnit == 'F' ? '°F' : '°C';
  }

  Future<void> changeTemperatureUnit(String unit) async {
    _temperatureUnit = unit;
    await storageService.saveTemperatureUnit(unit);
    notifyListeners();
  }

  Future<void> fetchWeatherByCity(String cityName) async {
    if (cityName.trim().isEmpty) {
      _state = WeatherState.error;
      _errorMessage = 'Vui lòng nhập tên thành phố.';
      notifyListeners();
      return;
    }

    _state = WeatherState.loading;
    _errorMessage = '';
    _isCachedData = false;
    notifyListeners();

    try {
      final weather = await weatherService.getCurrentWeatherByCity(cityName);
      final forecast = await weatherService.getForecastByCity(cityName);
      _currentWeather = weather;
      _forecast = forecast;
      _state = WeatherState.loaded;
      await storageService.saveWeatherData(weather);
      await storageService.addRecentSearch(weather.cityName);
      _lastUpdateTime = DateTime.now();
    } catch (e) {
      _state = WeatherState.error;
      _errorMessage = e.toString();
      await loadCachedWeather();
    }

    notifyListeners();
  }

  Future<void> fetchWeatherByLocation() async {
    _state = WeatherState.loading;
    _errorMessage = '';
    _isCachedData = false;
    notifyListeners();
    try {
      final position = await locationService.getCurrentLocation();

      final weather = await weatherService.getCurrentWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );

      final forecast = await weatherService.getForecastByCoordinates(
        position.latitude,
        position.longitude,
      );

      _currentWeather = weather;
      _forecast = forecast;
      _state = WeatherState.loaded;

      await storageService.saveWeatherData(weather);

      _lastUpdateTime = DateTime.now();
    } catch (e) {
      _state = WeatherState.error;
      _errorMessage = e.toString();
      await loadCachedWeather();
    }

    notifyListeners();
  }

  Future<void> loadCachedWeather() async {
    final cachedWeather = await storageService.getCachedWeather();

    if (cachedWeather != null) {
      _currentWeather = cachedWeather;
      _forecast = [];
      _isCachedData = true;
      _lastUpdateTime = await storageService.getLastUpdateTime();
      _state = WeatherState.loaded;
    }
  }

  Future<void> refreshWeather() async {
    if (_currentWeather != null) {
      await fetchWeatherByCity(_currentWeather!.cityName);
    } else {
      await fetchWeatherByLocation();
    }
  }

  Future<void> addCurrentCityToFavorites() async {
    if (_currentWeather == null) {
      return;
    }
    await storageService.addFavoriteCity(_currentWeather!.cityName);
  }
}