import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/models/weather_model.dart';

class StorageService {
  static const String _weatherKey = 'cached_weather';
  static const String _lastUpdateKey = 'last_update';
  static const String _favoriteCitiesKey = 'favorite_cities';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _temperatureUnitKey = 'temperature_unit';

  Future<void> saveWeatherData(WeatherModel weather) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weatherKey, jsonEncode(weather.toJson()));
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<WeatherModel?> getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final weatherJson = prefs.getString(_weatherKey);
    if (weatherJson == null) {
      return null;
    }

    final data = jsonDecode(weatherJson);
    return WeatherModel.fromJson(data);
  }

  Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);

    if (lastUpdate == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - lastUpdate;

    return difference < 30 * 60 * 1000;
  }

  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);

    if (lastUpdate == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(lastUpdate);
  }

  Future<List<String>> getFavoriteCities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteCitiesKey) ?? [];
  }

  Future<void> saveFavoriteCities(List<String> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteCitiesKey, cities);
  }

  Future<void> addFavoriteCity(String city) async {
    final cities = await getFavoriteCities();

    if (!cities.contains(city)) {
      cities.add(city);
    }

    if (cities.length > 5) {
      cities.removeAt(0);
    }

    await saveFavoriteCities(cities);
  }

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(String city) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];

    searches.remove(city);
    searches.insert(0, city);

    if (searches.length > 5) {
      searches.removeLast();
    }

    await prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<String> getTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_temperatureUnitKey) ?? 'C';
  }

  Future<void> saveTemperatureUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_temperatureUnitKey, unit);
  }
}