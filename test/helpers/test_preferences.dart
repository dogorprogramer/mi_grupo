import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_grupo/core/storage/preferences_service.dart';

Future<PreferencesService> createTestPreferencesService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return PreferencesService(prefs);
}
