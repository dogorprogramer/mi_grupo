import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
