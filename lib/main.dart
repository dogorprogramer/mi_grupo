import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers/storage_providers.dart';
import 'core/storage/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(PreferencesService(prefs)),
      ],
      child: const MiGrupoApp(),
    ),
  );
}
