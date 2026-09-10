import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_grupo/app/providers/storage_providers.dart';
import 'package:mi_grupo/app/providers/theme_provider.dart';
import 'package:mi_grupo/core/constants/app_constants.dart';
import 'package:mi_grupo/core/storage/preferences_service.dart';

Future<ProviderContainer> makeContainer() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      preferencesServiceProvider.overrideWithValue(PreferencesService(prefs)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system when nothing is stored', () async {
    final container = await makeContainer();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('reads the stored mode', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.themeModeKey: 'light',
    });
    final container = await makeContainer();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('setThemeMode updates the state and persists it', () async {
    final container = await makeContainer();

    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.themeModeKey), 'dark');
  });
}
