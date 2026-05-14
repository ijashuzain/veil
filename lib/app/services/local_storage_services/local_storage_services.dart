import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getString(String key) => _prefs?.getString(key);

  static Future<bool> setString(String key, String value) async {
    return _requirePrefs().setString(key, value);
  }

  static Future<bool> remove(String key) async => _requirePrefs().remove(key);

  static Future<bool> clear() async => _requirePrefs().clear();

  static SharedPreferences _requirePrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('LocalStorage.init() must be called before use.');
    }
    return prefs;
  }
}
